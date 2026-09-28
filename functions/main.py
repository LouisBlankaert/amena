import json
import urllib.error
import urllib.request

from firebase_functions import https_fn
from firebase_functions.options import set_global_options
from firebase_functions.params import SecretParam

# Plafond de coût : jamais plus de 10 instances en parallèle
set_global_options(max_instances=10)

# La clé Groq vit ici (Secret Manager), jamais dans l'app : une clé embarquée dans
# une app iOS peut être extraite du fichier téléchargé depuis l'App Store.
GROQ_API_KEY = SecretParam("GROQ_API_KEY")

ALLOWED_LANGUAGES = {"English", "French"}
MAX_THEME_LENGTH = 900  # thème le plus long de l'app : ~650 caractères avec 2 demandes du Carnet

HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST",
    "Access-Control-Allow-Headers": "Content-Type",
    "Content-Type": "application/json",
}


def _error(message: str, status: int) -> https_fn.Response:
    return https_fn.Response(json.dumps({"error": message}), status=status, headers=HEADERS)


def _prompt(theme: str, language: str) -> str:
    # Même consignes que l'app avant le passage par ce serveur (GeminiService.swift)
    return f"""IMPORTANT: You must write ONLY in {language}. Every single word must be in {language}.
Write a heartfelt Christian prayer of exactly 200 to 250 words in {language}.
Theme: {theme}.
- If French: start with one of these (vary each time): 'Seigneur,' or 'Dieu,' or 'Seigneur Jésus,' or 'Père,' — never use 'Père céleste'.
- If English: start with one of these (vary each time): 'Lord,' or 'Heavenly Father,' or 'Father,' or 'Dear God,'.
- Write at least 4 full paragraphs with rich, poetic language.
- Be personal, warm, and deeply emotional.
- If French: use correct French grammar. Never write 'je me prostre' — use 'je m'incline' or 'je me prosterne' instead.
- If French: when addressing God, use the formal 'vous' (vouvoiement) consistently throughout the entire prayer — never switch to 'tu' (tutoiement) mid-prayer.
- End with 'Au nom de Jésus, Amen.' if French, or 'In Jesus' name, Amen.' if English.
- Do NOT add any Bible reference or citation line: end the prayer with the Amen."""


def _strip_reference(prayer: str) -> str:
    # Une référence seule ("— Philippiens 4:6-7"), sans le texte du verset, n'explique rien
    # et l'IA peut se tromper de verset : les vrais versets exacts sont sur l'accueil.
    lines = prayer.rstrip().splitlines()
    while lines and lines[-1].strip()[:1] in ("—", "–", "-") and any(c.isdigit() for c in lines[-1]):
        lines.pop()
    return "\n".join(lines).rstrip()


@https_fn.on_request(secrets=[GROQ_API_KEY], invoker="public")
def generate_prayer(req: https_fn.Request) -> https_fn.Response:
    if req.method == "OPTIONS":
        return https_fn.Response("", status=204, headers=HEADERS)
    if req.method != "POST":
        return _error("Method not allowed", 405)

    # N'accepte que ce que l'app envoie : sinon n'importe qui pourrait se servir
    # de ce serveur comme d'une IA gratuite à nos frais
    body = req.get_json(silent=True) or {}
    theme = body.get("theme", "daily Christian prayer")
    language = body.get("language", "English")
    if not isinstance(theme, str) or not theme.strip() or len(theme) > MAX_THEME_LENGTH:
        return _error("Invalid theme", 400)
    if language not in ALLOWED_LANGUAGES:
        return _error("Invalid language", 400)

    payload = json.dumps({
        # llama-3.3-70b-versatile a été retiré par Groq ; gpt-oss-20b avec un raisonnement
        # "low" sinon le modèle dépense tous ses tokens à réfléchir et renvoie un texte vide
        "model": "openai/gpt-oss-20b",
        "messages": [{"role": "user", "content": _prompt(theme, language)}],
        "max_tokens": 600,
        "temperature": 0.7,
        "reasoning_effort": "low",
    }).encode("utf-8")

    try:
        groq_req = urllib.request.Request(
            "https://api.groq.com/openai/v1/chat/completions",
            data=payload,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {GROQ_API_KEY.value.strip()}",
                # Cloudflare (devant Groq) rejette l'agent par défaut "Python-urllib" (403, code 1010)
                "User-Agent": "amena-prayer-function/1.0",
            },
            method="POST",
        )
        with urllib.request.urlopen(groq_req, timeout=30) as resp:
            result = json.loads(resp.read().decode("utf-8"))
        prayer = (result["choices"][0]["message"].get("content") or "").strip()
        prayer = _strip_reference(prayer)
        if not prayer:
            return _error("Empty prayer", 502)
        return https_fn.Response(json.dumps({"prayer": prayer}, ensure_ascii=False), status=200, headers=HEADERS)
    except urllib.error.HTTPError as e:
        # Le détail reste dans les logs Firebase, pas dans la réponse publique
        print(f"Groq HTTP {e.code}: {e.read().decode('utf-8')[:300]}")
        return _error("Upstream error", 502)
    except Exception as e:
        print(f"generate_prayer failed: {e}")
        return _error("Internal error", 500)
