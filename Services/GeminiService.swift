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

    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"

    // Plusieurs prières de secours qui varient aléatoirement si l'API échoue
    private static let fallbackPrayers = [
        """
        Heavenly Father,

        Thank you for this new day. Help me to seek You first, before the noise of the world takes over. Fill me with Your peace and guide every step I take today.

        In Jesus' name, Amen.

        — Philippians 4:6-7
        """,
        """
        Lord,

        I come to You with a humble heart. Remind me today that time spent with You is never wasted. Let Your light shine through me and may my actions reflect Your love.

        In Jesus' name, Amen.

        — Psalm 16:11
        """,
        """
        Heavenly Father,

        Thank You for another chance to grow closer to You. Quiet the distractions around me and help me to hear Your voice clearly. I choose You above all else today.

        In Jesus' name, Amen.

        — Matthew 6:33
        """,
        """
        Lord,

        You are my strength and my refuge. When I feel pulled away by the world, draw me back to You. Help me to be still and know that You are God.

        In Jesus' name, Amen.

        — Psalm 46:10
        """,
        """
        Heavenly Father,

        Thank You for Your faithfulness that is new every morning. I surrender this day to You — my time, my thoughts, my phone. Use me for Your glory.

        In Jesus' name, Amen.

        — Lamentations 3:22-23
        """
    ]

    // Retourne une prière aléatoire parmi les prières de secours
    static var fallbackPrayer: String {
        fallbackPrayers.randomElement() ?? fallbackPrayers[0]
    }

    // Génère une prière en appelant l'API Gemini
    // throws = peut générer une erreur (pas de réseau, etc.)
    // async = fonction asynchrone (n'a pas besoin d'un callback)
    func generatePrayer(theme: String = "daily Christian prayer") async throws -> String {
        let apiKey = Secrets.geminiAPIKey

        print("🔑 Gemini key length: \(apiKey.count), prefix: \(String(apiKey.prefix(6)))")

        guard !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY_HERE" else {
            print("❌ Gemini key not set")
            throw GeminiError.invalidURL
        }

        // Clé directement dans l'URL — méthode la plus universelle pour Gemini REST API
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }

        // Corps de la requête au format JSON attendu par Gemini
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": """
                            Generate a heartfelt Christian prayer. \
                            Theme: \(theme). \
                            Include a Biblical reference at the end. \
                            Around 150-200 words. \
                            Warm, personal and poetic tone. \
                            Start with 'Heavenly Father' or 'Lord'. \
                            Use paragraph breaks for rhythm. \
                            End with 'Amen.' followed by the Biblical reference on a new line.
                            """
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "maxOutputTokens": 2000,
                "temperature": 0.7
            ]
        ]

        // Conversion du dictionnaire Swift en JSON
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = jsonData
        request.timeoutInterval = 20

        // Appel réseau asynchrone (attend la réponse sans bloquer l'UI)
        let (data, response) = try await URLSession.shared.data(for: request)

        // Vérifie le code HTTP — si erreur, on throw pour que l'appelant sache
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        let statusCode = httpResponse.statusCode
        print("📡 Gemini HTTP status: \(statusCode)")
        guard statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("⚠️ Gemini error body: \(body.prefix(500))")
            // On inclut le code HTTP dans l'erreur pour l'afficher à l'écran
            throw NSError(domain: "Gemini", code: statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "HTTP \(statusCode): \(body.prefix(200))"])
        }

        let text = try parseResponse(data: data)
        print("✅ Gemini prayer generated (\(text.count) chars)")
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
}

// Erreurs spécifiques au service Gemini
enum GeminiError: Error {
    case invalidURL
    case invalidResponse
    case noContent
}
