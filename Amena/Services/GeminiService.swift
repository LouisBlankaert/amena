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

    // URL de l'API Gemini
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

    // Prière de secours si l'API échoue (pas de connexion, clé invalide, etc.)
    static let fallbackPrayer = """
    Heavenly Father,

    Thank you for this new day and the opportunity to seek Your presence. Help me to put You first before all distractions and to build a closer relationship with You through prayer.

    Guide my steps today, grant me wisdom, and fill my heart with Your peace that surpasses all understanding.

    In Jesus' name, Amen.

    — Philippians 4:6-7
    """

    // Génère une prière en appelant l'API Gemini
    // throws = peut générer une erreur (pas de réseau, etc.)
    // async = fonction asynchrone (n'a pas besoin d'un callback)
    func generatePrayer(theme: String = "daily Christian prayer") async throws -> String {
        let apiKey = Secrets.geminiAPIKey

        // Vérifie que la clé est configurée
        guard !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY_HERE" else {
            return GeminiService.fallbackPrayer
        }

        // Construction de l'URL avec la clé API
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
                            Generate a short, heartfelt Christian prayer. \
                            Theme: \(theme). \
                            Include a Biblical reference at the end. \
                            Maximum 100 words. \
                            Warm and personal tone. \
                            Start with 'Heavenly Father' or 'Lord'. \
                            End with 'Amen.' followed by the Biblical reference.
                            """
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "maxOutputTokens": 200,
                "temperature": 0.7
            ]
        ]

        // Conversion du dictionnaire Swift en JSON
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        // Configuration de la requête HTTP
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 15  // 15 secondes max

        // Appel réseau asynchrone (attend la réponse sans bloquer l'UI)
        let (data, response) = try await URLSession.shared.data(for: request)

        // Vérifie le code HTTP
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return GeminiService.fallbackPrayer
        }

        // Parsing de la réponse JSON
        return try parseResponse(data: data)
    }

    // Extrait le texte de la réponse Gemini
    private func parseResponse(data: Data) throws -> String {
        // Structure attendue de la réponse Gemini
        struct GeminiResponse: Codable {
            struct Candidate: Codable {
                struct Content: Codable {
                    struct Part: Codable {
                        let text: String
                    }
                    let parts: [Part]
                }
                let content: Content
            }
            let candidates: [Candidate]
        }

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = decoded.candidates.first?.content.parts.first?.text else {
            return GeminiService.fallbackPrayer
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
