import json
import urllib.request
from firebase_functions import https_fn
from firebase_functions.options import set_global_options
from firebase_functions.params import SecretParam

set_global_options(max_instances=10)

GROQ_API_KEY = SecretParam("GROQ_API_KEY")

@https_fn.on_request(secrets=[GROQ_API_KEY], invoker="public")
def generate_prayer(req: https_fn.Request) -> https_fn.Response:
    headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers": "Content-Type",
        "Content-Type": "application/json"
    }

    if req.method == "OPTIONS":
        return https_fn.Response("", status=204, headers=headers)

    if req.method != "POST":
        return https_fn.Response(
            json.dumps({"error": "Method not allowed"}),
            status=405, headers=headers
        )

    try:
        body = req.get_json()
        theme = body.get("theme", "daily Christian prayer")
        language = body.get("language", "English")
    except Exception:
        return https_fn.Response(
            json.dumps({"error": "Invalid request body"}),
            status=400, headers=headers
        )

    prompt = f"""IMPORTANT: You must write ONLY in {language}. Every single word must be in {language}.
Write a heartfelt Christian prayer of exactly 200 to 250 words in {language}.
Theme: {theme}.
- If French: start with one of these (vary each time): 'Seigneur,' or 'Dieu,' or 'Seigneur Jesus,' or 'Pere,' - never use 'Pere celeste'.
- If English: start with one of these (vary each time): 'Lord,' or 'Heavenly Father,' or 'Father,' or 'Dear God,'.
- Write at least 4 full paragraphs with rich, poetic language.
- Be personal, warm, and deeply emotional.
- If French: use correct French grammar. Never write 'je me prostre' - use 'je m incline' or 'je me prosterne' instead.
- End with 'Au nom de Jesus, Amen.' if French, or 'In Jesus name, Amen.' if English.
- Add the Biblical reference on the last line starting with '-- '."""

    payload = json.dumps({
        "model": "llama-3.3-70b-versatile",
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 600,
        "temperature": 0.7
    }).encode("utf-8")

    import urllib.error
    try:
        groq_req = urllib.request.Request(
            "https://api.groq.com/openai/v1/chat/completions",
            data=payload,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {GROQ_API_KEY.value.strip()}"
            },
            method="POST"
        )
        with urllib.request.urlopen(groq_req, timeout=30) as resp:
            result = json.loads(resp.read().decode("utf-8"))
            prayer = result["choices"][0]["message"]["content"].strip()

        return https_fn.Response(
            json.dumps({"prayer": prayer}),
            status=200, headers=headers
        )
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        return https_fn.Response(
            json.dumps({"error": f"Groq HTTP {e.code}", "detail": body}),
            status=500, headers=headers
        )
    except Exception as e:
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500, headers=headers
        )
