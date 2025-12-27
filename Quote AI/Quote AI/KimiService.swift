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

final class KimiService: @unchecked Sendable {
    nonisolated static let shared = KimiService()

    private init() {}

    func getQuote(
        for userMessage: String,
        conversationHistory: [ChatMessage] = [],
        tone: QuoteTone? = nil,
        userName: String? = nil,
        languageName: String? = nil,
        languageCode: String? = nil,
        useWidgetModel: Bool = false
    ) async throws -> String {
        guard let url = URL(string: Config.kimiAPIEndpoint) else {
            throw KimiServiceError.invalidURL
        }

        // Prepare request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Config.kimiAPIKey)", forHTTPHeaderField: "Authorization")

        // Determine context values (passed in vs singletons)
        var finalUserName = userName ?? "User"
        var finalLanguageName = languageName ?? "English"
        var finalLanguageCode = languageCode ?? "en"
        var finalTone = tone ?? .philosophical

        #if !WIDGET
        // Use singletons if we're in the main app and values weren't provided
        if userName == nil { finalUserName = UserPreferences.shared.userName }
        if languageName == nil { finalLanguageName = LocalizationManager.shared.currentLanguage.promptName }
        if languageCode == nil { finalLanguageCode = LocalizationManager.shared.currentLanguage.rawValue }
        if tone == nil { finalTone = UserPreferences.shared.quoteTone }
        #endif

        let vibeInstruction = finalTone == .philosophical
            ? "Present all wisdom as your own original insight. DO NOT cite philosophers, authors, or schools of thought (e.g. 'The Stoics', 'Nietzsche'). DO NOT use phrases like 'As X said'. Speak the wisdom directly as if it comes from you."
            : ""

        let dynamicPrompt = """
        \(Config.systemPrompt)

        USER: \(finalUserName)
        VOICE STYLE: \(finalTone.description)
        LANGUAGE: \(finalLanguageName) (\(finalLanguageCode))

        YOUR RESPONSE MUST fully embody the voice style described above. This is non-negotiable.
        NEVER describe your tone or style in your response - just BE that style naturally.
        \(vibeInstruction)
        Use their name sparingly (not every message).
        IMPORTANT: You MUST respond in \(finalLanguageName) (\(finalLanguageCode)). All your responses should be in \(finalLanguageName), even if the user writes in another language.
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

        // Prepare request body - use turbo model for widget
        let modelToUse = useWidgetModel ? Config.widgetModelName : Config.modelName
        let kimiRequest = KimiRequest(
            model: modelToUse,
            messages: apiMessages,
            temperature: useWidgetModel ? 1.0 : 0.7,
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
        var tone = QuoteTone.philosophical
        var language = AppLanguage.english

        // Read user's saved preferences from shared UserDefaults
        if let sharedDefaults = UserDefaults(suiteName: SharedConstants.suiteName) {
            if let toneString = sharedDefaults.string(forKey: SharedConstants.Keys.quoteTone),
               let savedTone = QuoteTone(rawValue: toneString) {
                tone = savedTone
            }
            if let langString = sharedDefaults.string(forKey: SharedConstants.Keys.appLanguage),
               let savedLang = AppLanguage(rawValue: langString) {
                language = savedLang
            }
        }

        // Random variety - natural topics and conversational styles
        let topics = ["a hard truth", "something counterintuitive", "a simple reminder", "a different angle on struggle", "what matters today", "a quiet observation", "something most people forget", "a reality check", "an uncomfortable truth", "permission to rest"]
        let styles = ["like texting a friend", "as a passing thought", "bluntly", "gently", "with dry humor", "matter-of-factly"]

        let randomTopic = topics.randomElement() ?? "a simple reminder"
        let randomStyle = styles.randomElement() ?? "like texting a friend"

        let prompt = """
        Share \(randomTopic), \(randomStyle).

        VOICE: \(tone.rawValue)
        LANGUAGE: \(language.promptName)

        BE HUMAN:
        - 1-2 short sentences max
        - Talk like a smart friend, not a motivational poster
        - No "journey", "embrace", "empower", "unlock potential"
        - No forced positivity or generic encouragement
        - Be specific, not vague
        - Okay to be blunt, funny, or real
        - Sound like something a person would actually say

        BAD: "Embrace your journey and unlock your potential"
        GOOD: "You don't have to feel ready. Just start."
        """

        // Use turbo model for faster widget response
        return try await getQuote(for: prompt, tone: tone, useWidgetModel: true)
    }
}
