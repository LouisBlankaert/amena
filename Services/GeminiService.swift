// GeminiService : génère des prières via l'API Gemini de Google
// Utilise async/await (Swift moderne) pour les appels réseau
// La clé API est dans Secrets.swift (JAMAIS commitée)

import Foundation

// Singleton : une seule instance partagée dans toute l'app
// "shared" = pattern standard iOS pour les services
// @unchecked Sendable : on déclare manuellement que ce singleton est thread-safe
// (toutes ses méthodes sont async ou n'accèdent pas à un état mutable partagé)
final class GeminiService: @unchecked Sendable {
    static let shared = GeminiService()
    private init() {}

    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

    // Plusieurs prières de secours qui varient aléatoirement si l'API échoue
    private static let fallbackPrayers = [
        """
        Heavenly Father,

        Thank You for this new day — a gift I did not earn and yet You give freely. As I open my eyes and reach for this phone, remind me first to reach for You. The world moves so fast, Lord, and the noise is endless. But You are the still small voice beneath it all, and I choose to listen.

        Help me to seek You before I seek anything else today. Before the notifications, before the scrolling, before the rushing — let me be still in Your presence. Fill my heart with the peace that surpasses all understanding, a peace the world cannot manufacture and cannot take away.

        Guide every step I take, every word I speak, every decision I make. May my actions today reflect Your love and not the anxious pace of this world. I trust that You hold this day, and I surrender it fully to You.

        In Jesus' name, Amen.

        — Philippians 4:6-7
        """,
        """
        Lord,

        I come before You this morning with a humble and grateful heart. You have been faithful yesterday, You are faithful today, and I trust You will be faithful tomorrow. Your mercies are new every morning — and I need them desperately.

        Remind me today that every moment spent with You is never wasted. The world tells me to be productive, to be fast, to be seen. But You call me to be still, to be known by You, and to walk in Your truth. Help me to choose Your way over my own.

        Let Your light shine through me in every interaction. Where there is conflict, make me a peacemaker. Where there is darkness, make me a light. Where there is need, make me generous. I want to look back at this day and see Your fingerprints all over it.

        In Jesus' name, Amen.

        — Psalm 16:11
        """,
        """
        Heavenly Father,

        In the quiet of this moment, before the day pulls me in a hundred directions, I choose to sit with You. Thank You for drawing me back — for placing in me this hunger to know You more deeply, to love You more truly.

        Quiet the noise within me, Lord. Silence the fears, the worries, the distractions that crowd my mind. Tune my heart to hear Your voice above all others. You speak in whispers, and I want to be close enough to hear every word You say to me.

        I give You this day — all of it. The meetings, the meals, the moments in between. Use even the mundane things for Your glory. Let gratitude be the lens through which I see everything today. I choose You above the scroll, above the screen, above every temporary thing.

        In Jesus' name, Amen.

        — Matthew 6:33
        """,
        """
        Lord,

        You are my strength when I have none left, my refuge when the world feels too heavy, my rock when everything around me shifts. I come to You not because I have it together, but precisely because I don't — and You are the only One who does.

        When I feel the pull of distraction, draw me back to You. When I feel anxious about what others think, remind me of what You think — that I am loved, chosen, and held. When I feel the temptation to fill every quiet moment with noise, help me instead to fill it with Your presence.

        Be still, You say. And know that I am God. Let those words settle into the deepest part of me today, Lord. You are God. That changes everything. I can rest because You are in control. I can trust because You are good. I can love because You first loved me.

        In Jesus' name, Amen.

        — Psalm 46:10
        """,
        """
        Heavenly Father,

        Your faithfulness is new every single morning — and I need it every single morning. Thank You for not giving up on me, for pursuing me even when I wander, for loving me even in my most distracted and faithless moments.

        I surrender this day to You completely. My time is Yours. My thoughts are Yours. Even this phone in my hand — I offer it back to You. Use it or put it down, whichever glorifies You more. May every hour today be lived with intention and with love.

        Stir in me a deeper hunger for Your Word, a deeper desire for prayer, a deeper courage to live differently than the world around me. I don't want to sleepwalk through my days anymore. I want to live wide awake, fully alive in You.

        In Jesus' name, Amen.

        — Lamentations 3:22-23
        """
    ]

    private static let fallbackPrayersFR = [
        """
        Père céleste,

        Je viens à Toi en ce nouveau matin, le cœur plein de gratitude. Tu m'as accordé une nouvelle journée — un cadeau que je n'ai pas mérité, et pourtant Tu me le donnes librement. Avant que le monde me réclame, je choisis de m'asseoir avec Toi.

        Apaise le bruit en moi, Seigneur. Fais taire les peurs, les soucis, les distractions qui encombrent mon esprit. Accorde-moi cette paix qui dépasse toute compréhension — une paix que le monde ne peut ni fabriquer ni reprendre.

        Guide chacun de mes pas aujourd'hui. Que mes paroles soient douces, mes pensées nobles, et mes actions reflet de Ton amour. Je Te donne cette journée entière — les réunions, les repas, les moments entre les deux. Utilise-les tous pour Ta gloire.

        Je choisis Ton visage avant l'écran, Ta voix avant le bruit. Reste proche de moi, Père.

        Au nom de Jésus, Amen.

        — Philippiens 4:6-7
        """,
        """
        Seigneur,

        Ta fidélité est nouvelle chaque matin — et j'en ai besoin chaque matin. Merci de ne pas m'avoir abandonné, de me poursuivre même dans mes moments de distraction et de faiblesse.

        Aujourd'hui, aide-moi à Te chercher avant toute chose. Avant les notifications, avant les réseaux, avant la précipitation — que je sois immobile dans Ta présence. Remplis mon cœur de force et de lumière pour affronter cette journée.

        Que Ta lumière brille à travers moi dans chaque rencontre. Là où il y a du conflit, fais de moi un artisan de paix. Là où il y a de l'obscurité, fais de moi une lumière. Je veux regarder en arrière sur cette journée et voir Tes empreintes partout.

        Tu es Dieu. Cela change tout.

        Au nom de Jésus, Amen.

        — Psaume 16:11
        """
    ]

    // Retourne une prière selon la langue sélectionnée
    static func fallbackPrayerForLanguage(_ language: String) -> String {
        if language == "French" {
            return fallbackPrayersFR.randomElement() ?? fallbackPrayersFR[0]
        }
        return fallbackPrayers.randomElement() ?? fallbackPrayers[0]
    }

    static var fallbackPrayer: String {
        fallbackPrayers.randomElement() ?? fallbackPrayers[0]
    }

    func generatePrayer(theme: String = "daily Christian prayer", language: String = "English") async throws -> String {
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            throw GeminiError.invalidURL
        }

        let prompt = """
        IMPORTANT: You must write ONLY in \(language). Every single word must be in \(language).
        Write a heartfelt Christian prayer of exactly 200 to 250 words in \(language).
        Theme: \(theme).
        - If French: start with one of these (vary each time): 'Seigneur,' or 'Dieu,' or 'Seigneur Jésus,' or 'Père,' — never use 'Père céleste'.
        - If English: start with one of these (vary each time): 'Lord,' or 'Heavenly Father,' or 'Father,' or 'Dear God,'.
        - Write at least 4 full paragraphs with rich, poetic language.
        - Be personal, warm, and deeply emotional.
        - If French: use correct French grammar. Never write 'je me prostre' — use 'je m'incline' or 'je me prosterne' instead.
        - End with 'Au nom de Jésus, Amen.' if French, or 'In Jesus' name, Amen.' if English.
        - Add the Biblical reference on the last line starting with '— '.
        """

        let requestBody: [String: Any] = [
            "model": "llama-3.3-70b-versatile",
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": 600,
            "temperature": 0.7
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Secrets.groqAPIKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        print("📡 Groq status: \(httpResponse.statusCode)")
        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("⚠️ Groq error: \(body.prefix(300))")
            throw NSError(domain: "Groq", code: httpResponse.statusCode)
        }

        let text = try parseGroqResponse(data: data)
        print("✅ Prayer generated via Groq (\(text.count) chars)")
        return text
    }

    // Extrait le texte de la réponse Gemini
    // Gemini 3 peut retourner des "thought parts" (internes) — on les filtre
    private func parseResponse(data: Data) throws -> String {
        struct GeminiResponse: Codable {
            struct Candidate: Codable {
                struct Content: Codable {
                    struct Part: Codable {
                        let text: String?
                        let thought: Bool?   // true = partie "thinking" interne, à ignorer
                    }
                    let parts: [Part]
                }
                let content: Content
            }
            let candidates: [Candidate]
        }

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        let parts = decoded.candidates.first?.content.parts ?? []
        // On prend la première partie qui N'EST PAS du "thinking" interne
        guard let text = parts.first(where: { $0.thought != true })?.text else {
            throw GeminiError.noContent
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseGroqResponse(data: Data) throws -> String {
        struct GroqResponse: Codable {
            struct Choice: Codable {
                struct Message: Codable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }
        let decoded = try JSONDecoder().decode(GroqResponse.self, from: data)
        guard let text = decoded.choices.first?.message.content else {
            throw GeminiError.noContent
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// Erreurs spécifiques au service Gemini
enum GeminiError: Error {
    case invalidURL
    case invalidResponse
    case noContent
}
