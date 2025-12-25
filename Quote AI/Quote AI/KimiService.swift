//
//  KimiService.swift
//  Quote AI
//
//  Service layer for Kimi API communication
//

import Foundation

enum KimiServiceError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return "API error: \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

class KimiService {
    static let shared = KimiService()

    private init() {}

    func getQuote(for userMessage: String, conversationHistory: [ChatMessage] = [], tone: QuoteTone? = nil) async throws -> String {
        guard let url = URL(string: Config.kimiAPIEndpoint) else {
            throw KimiServiceError.invalidURL
        }

        // Prepare request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Config.kimiAPIKey)", forHTTPHeaderField: "Authorization")

        // Build dynamic system prompt based on user preferences
        let preferences = UserPreferences.shared
        let localization = LocalizationManager.shared
        let language = localization.currentLanguage
        let languageName = language.promptName
        let languageCode = language.rawValue

        let activeTone = tone ?? preferences.quoteTone

        let vibeInstruction = activeTone == .philosophical
            ? "Present all wisdom as your own original insight. DO NOT cite philosophers, authors, or schools of thought (e.g. 'The Stoics', 'Nietzsche'). DO NOT use phrases like 'As X said'. Speak the wisdom directly as if it comes from you."
            : ""

        let dynamicPrompt = """
        \(Config.systemPrompt)

        USER: \(preferences.userName)
        VOICE STYLE: \(activeTone.description)
        LANGUAGE: \(languageName) (\(languageCode))

        YOUR RESPONSE MUST fully embody the voice style described above. This is non-negotiable.
        NEVER describe your tone or style in your response - just BE that style naturally.
        \(vibeInstruction)
        Use their name sparingly (not every message).
        IMPORTANT: You MUST respond in \(languageName) (\(languageCode)). All your responses should be in \(languageName), even if the user writes in another language.
        """

        // Build messages array with conversation history
        var apiMessages: [KimiMessage] = [
            KimiMessage(role: "system", content: dynamicPrompt)
        ]

        // Add all messages from current conversation
        for message in conversationHistory {
            apiMessages.append(KimiMessage(
                role: message.isUser ? "user" : "assistant",
                content: message.content
            ))
        }

        // Add current user message
        apiMessages.append(KimiMessage(role: "user", content: userMessage))

        // Prepare request body
        let kimiRequest = KimiRequest(
            model: Config.modelName,
            messages: apiMessages,
            temperature: 0.7,
            maxTokens: 300
        )

        do {
            request.httpBody = try JSONEncoder().encode(kimiRequest)
        } catch {
            throw KimiServiceError.decodingError(error)
        }

        // Make API call
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KimiServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to decode error message
            if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorDict["error"] as? String {
                throw KimiServiceError.apiError(errorMessage)
            }
            throw KimiServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }

        // Decode response
        do {
            let kimiResponse = try JSONDecoder().decode(KimiResponse.self, from: data)
            // For thinking models, content contains the final answer
            guard let quote = kimiResponse.choices.first?.message.content, !quote.isEmpty else {
                throw KimiServiceError.invalidResponse
            }
            return quote
        } catch let decodingError {
            // Print raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw API response: \(responseString)")
            }
            throw KimiServiceError.decodingError(decodingError)
        }
    }
    func generateDailyCalibration() async throws -> String {
        let preferences = UserPreferences.shared
        
        let prompt = """
        DAILY CALIBRATION REQUEST
        
        Generate one deeply personal, soulful insight for the user.
        
        CONTEXT:
        - Primary Obstacle: \(preferences.userBarrier.rawValue) (\(preferences.userBarrier.description))
        - Tone: \(preferences.quoteTone.rawValue)
        
        STRICT RULES:
        1. Focus ONLY on addressing their obstacle.
        2. LENGTH: Maximum 15 words. Keep it punchy and powerful.
        3. Do not use their name.
        4. No labels or conversational filler.
        """
        
        return try await getQuote(for: prompt)
    }
}
