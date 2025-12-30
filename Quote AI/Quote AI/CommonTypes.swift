//
//  CommonTypes.swift
//  Quote AI
//
//  Shared types between main app and extensions
//

import Foundation

enum QuoteTone: String, CaseIterable, Codable {
    case naval = "Navalism"
    case toughLove = "Tough Love"
    case philosophical = "Philosophical"
    case realist = "Realist"

    var description: String {
        switch self {
        case .naval: return "Speak like Naval Ravikant."
        case .toughLove: return "Direct, no-nonsense, and challenging. Push the user to take action. Be blunt and straightforward."
        case .philosophical: return "Deep, contemplative, and thought-provoking. Reference philosophy, existentialism, stoicism. Make them think."
        case .realist: return "Practical, grounded, and honest. Focus on facts and actionable steps. Skip the fluff."
        }
    }
}

enum UserFocus: String, CaseIterable, Codable {
    case anxiety = "Overcoming Anxiety"
    case innerPeace = "Finding Inner Peace"
    case perspective = "Gaining Perspective"
    case confidence = "Building Confidence"
}

enum UserBarrier: String, CaseIterable, Codable {
    case procrastination = "Procrastination"
    case selfDoubt = "Self-Doubt"
    case burnout = "Burnout"
    case lackOfClarity = "Lack of Clarity"
    case externalFactors = "External Factors"
}

enum UserEnergyDrain: String, CaseIterable, Codable {
    case career = "Career"
    case relationship = "Relationship"
    case mediaNews = "Media & News"
    case healthFitness = "Health & Fitness"
}

enum ChatBackground: String, CaseIterable, Codable {
    case summit = "summit"
    case ascent = "ascent"
    case dawnRun = "dawnRun"
    case defaultBackground = "default"
}

enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case chinese = "zh"
    case hindi = "hi"
    case japanese = "ja"
    case korean = "ko"

    var promptName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .chinese: return "Chinese"
        case .hindi: return "Hindi"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        }
    }
}
