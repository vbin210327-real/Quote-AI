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

    func getQuote(for userMessage: String) async throws -> String {
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
        let dynamicPrompt = """
        \(Config.systemPrompt)

        USER: \(preferences.userName)
        TONE: \(preferences.quoteTone.rawValue) - \(preferences.quoteTone.description)

        YOUR RESPONSE MUST embody the \(preferences.quoteTone.rawValue) tone completely. This is non-negotiable.
        Use their name sparingly (not every message).
        """

        // Prepare request body
        let kimiRequest = KimiRequest(
            model: Config.modelName,
            messages: [
                KimiMessage(role: "system", content: dynamicPrompt),
                KimiMessage(role: "user", content: userMessage)
            ],
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
}
