//
//  UserPreferences.swift
//  Quote AI
//
//  Manages user personalization settings
//

import Foundation
import Combine

enum QuoteTone: String, CaseIterable, Codable {
    case gentle = "Gentle"
    case toughLove = "Tough Love"
    case philosophical = "Philosophical"
    case realist = "Realist"
    
    var description: String {
        switch self {
        case .gentle: return "You are doing your best, and that is enough."
        case .toughLove: return "Stop making excuses. Get to work."
        case .philosophical: return "We suffer more in imagination than in reality."
        case .realist: return "Motivation is overrated; consistency is compound interest. Your current feeling is temporary data, not a permanent directive"
        }
    }
    
    var icon: String {
        switch self {
        case .gentle: return "heart.fill"
        case .toughLove: return "flame.fill"
        case .philosophical: return "brain.head.profile"
        case .realist: return "chart.line.uptrend.xyaxis"
        }
    }
}

enum UserFocus: String, CaseIterable, Codable {
    case anxiety = "Overcoming Anxiety"
    case innerPeace = "Finding Inner Peace"
    case perspective = "Gaining Perspective"
    case confidence = "Building Confidence"
    
    var description: String {
        switch self {
        case .anxiety: return "I need calm and grounding."
        case .innerPeace: return "I seek tranquility and balance."
        case .perspective: return "I'm stuck and need clarity."
        case .confidence: return "I need to believe in myself."
        }
    }
    
    var icon: String {
        switch self {
        case .anxiety: return "cloud.sun.fill"
        case .innerPeace: return "leaf.fill"
        case .perspective: return "lightbulb.fill"
        case .confidence: return "star.fill"
        }
    }
}

enum UserBarrier: String, CaseIterable, Codable {
    case procrastination = "Procrastination"
    case selfDoubt = "Self-Doubt"
    case burnout = "Burnout"
    case lackOfClarity = "Lack of Clarity"
    case externalFactors = "External Factors"
    
    var description: String {
        switch self {
        case .procrastination: return "I keep putting things off."
        case .selfDoubt: return "I don't believe in myself."
        case .burnout: return "I feel exhausted and drained."
        case .lackOfClarity: return "I'm unsure of my direction."
        case .externalFactors: return "Things outside my control."
        }
    }
    
    var icon: String {
        switch self {
        case .procrastination: return "clock.arrow.circlepath"
        case .selfDoubt: return "person.wave.2.fill"
        case .burnout: return "battery.0percent"
        case .lackOfClarity: return "location.slash.fill"
        case .externalFactors: return "wind"
        }
    }
}

enum UserEnergyDrain: String, CaseIterable, Codable {
    case career = "Career"
    case relationship = "Relationship"
    case mediaNews = "Media & News"
    case healthFitness = "Health & Fitness"

    var description: String {
        switch self {
        case .career: return "Work stress is weighing on me."
        case .relationship: return "Personal connections are draining."
        case .mediaNews: return "Information overload is exhausting."
        case .healthFitness: return "My physical wellbeing needs attention."
        }
    }

    var icon: String {
        switch self {
        case .career: return "briefcase.fill"
        case .relationship: return "heart.fill"
        case .mediaNews: return "newspaper.fill"
        case .healthFitness: return "dumbbell.fill"
        }
    }
}

enum UserGeneration: String, CaseIterable, Codable {
    case genAlpha = "Gen Alpha"       // 2013-2024
    case genZ = "Gen Z"               // 1997-2012
    case millennial = "Millennial"    // 1981-1996
    case genX = "Gen X"               // 1965-1980
    case boomer = "Baby Boomer"       // 1946-1964
    case silent = "Silent Generation" // Before 1946

    static func from(birthYear: Int) -> UserGeneration {
        let currentYear = Calendar.current.component(.year, from: Date())
        switch birthYear {
        case 2013...currentYear:
            return .genAlpha
        case 1997...2012:
            return .genZ
        case 1981...1996:
            return .millennial
        case 1965...1980:
            return .genX
        case 1946...1964:
            return .boomer
        default:
            return .silent
        }
    }

    var toneModifier: String {
        switch self {
        case .genAlpha:
            return "Use simple, encouraging language. Keep it positive and relatable for young minds. Avoid complex philosophical concepts."
        case .genZ:
            return "Feel free to use casual, authentic language. You can reference modern struggles like social media pressure, climate anxiety, or career uncertainty. Be real, not preachy. Occasional use of relatable expressions is okay (like 'lowkey', 'vibe', 'no cap') but don't overdo it."
        case .millennial:
            return "Reference the balance between ambition and burnout, the pressure of adulting, and finding meaning. You can be slightly self-aware and ironic. Acknowledge the challenges of their life stage."
        case .genX:
            return "Be direct and pragmatic. Skip the fluff. They appreciate independence and resilience. Reference work-life balance and the wisdom that comes from experience."
        case .boomer:
            return "Use more traditional, respectful language. Reference wisdom gained through life experience. Focus on legacy, gratitude, and the value of perseverance."
        case .silent:
            return "Be respectful and warm. Reference timeless wisdom and life experience. Keep language classic and dignified."
        }
    }

    var yearRange: String {
        switch self {
        case .genAlpha: return "2013-present"
        case .genZ: return "1997-2012"
        case .millennial: return "1981-1996"
        case .genX: return "1965-1980"
        case .boomer: return "1946-1964"
        case .silent: return "Before 1946"
        }
    }
}

enum ChatBackground: String, CaseIterable, Codable {
    case orbit = "orbit"
    case summit = "summit"
    case depths = "depths"
    case ascent = "ascent"

    var assetName: String {
        switch self {
        case .orbit: return "ChatBackgroundOrbit"
        case .summit: return "ChatBackgroundSummit"
        case .depths: return "ChatBackgroundDepths"
        case .ascent: return "ChatBackgroundStairs"
        }
    }

    var displayName: String {
        switch self {
        case .orbit: return "Orbital Night"
        case .summit: return "Summit Trail"
        case .depths: return "Blue Depths"
        case .ascent: return "Monochrome Ascent"
        }
    }

    var description: String {
        switch self {
        case .orbit: return "Calm, focused, infinite."
        case .summit: return "Clear air, steady progress."
        case .depths: return "Deep work, quiet clarity."
        case .ascent: return "Minimal, disciplined, sharp."
        }
    }
}

class UserPreferences: ObservableObject {
    static let shared = UserPreferences()
    
    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "userName") }
    }
    
    @Published var userGender: String {
        didSet {
            UserDefaults.standard.set(userGender, forKey: "userGender")
        }
    }
    @Published var quoteTone: QuoteTone {
        didSet { UserDefaults.standard.set(quoteTone.rawValue, forKey: "quoteTone") }
    }
    
    @Published var userFocus: UserFocus {
        didSet { UserDefaults.standard.set(userFocus.rawValue, forKey: "userFocus") }
    }
    
    @Published var userBarrier: UserBarrier {
        didSet { UserDefaults.standard.set(userBarrier.rawValue, forKey: "userBarrier") }
    }
    
    @Published var userEnergyDrain: UserEnergyDrain {
        didSet { UserDefaults.standard.set(userEnergyDrain.rawValue, forKey: "userEnergyDrain") }
    }
    
    @Published var mentalEnergy: Double {
        didSet { UserDefaults.standard.set(mentalEnergy, forKey: "mentalEnergy") }
    }

    @Published var userBirthYear: Int {
        didSet { UserDefaults.standard.set(userBirthYear, forKey: "userBirthYear") }
    }

    var userGeneration: UserGeneration {
        return UserGeneration.from(birthYear: userBirthYear)
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    @Published var hasSeenWelcome: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenWelcome, forKey: "hasSeenWelcome")
        }
    }

    @Published var hasPlayedWelcomeIntro: Bool {
        didSet {
            UserDefaults.standard.set(hasPlayedWelcomeIntro, forKey: "hasPlayedWelcomeIntro")
        }
    }

    @Published var chatBackground: ChatBackground {
        didSet {
            UserDefaults.standard.set(chatBackground.rawValue, forKey: "chatBackground")
        }
    }
    private init() {
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        self.userGender = UserDefaults.standard.string(forKey: "userGender") ?? ""
        
        if let toneString = UserDefaults.standard.string(forKey: "quoteTone"),
           let tone = QuoteTone(rawValue: toneString) {
            self.quoteTone = tone
        } else {
            self.quoteTone = .gentle
        }
        
        if let focusString = UserDefaults.standard.string(forKey: "userFocus"),
           let focus = UserFocus(rawValue: focusString) {
            self.userFocus = focus
        } else {
            self.userFocus = .innerPeace
        }
        
        if let barrierString = UserDefaults.standard.string(forKey: "userBarrier"),
           let barrier = UserBarrier(rawValue: barrierString) {
            self.userBarrier = barrier
        } else {
            self.userBarrier = .procrastination
        }
        
        if let energyDrainString = UserDefaults.standard.string(forKey: "userEnergyDrain"),
           let energyDrain = UserEnergyDrain(rawValue: energyDrainString) {
            self.userEnergyDrain = energyDrain
        } else {
            self.userEnergyDrain = .career
        }
        
        let savedMentalEnergy = UserDefaults.standard.double(forKey: "mentalEnergy")
        if savedMentalEnergy == 0 && !UserDefaults.standard.bool(forKey: "mentalEnergySet") {
            self.mentalEnergy = 0.5 // Default to middle
        } else {
            self.mentalEnergy = savedMentalEnergy
        }

        let savedBirthYear = UserDefaults.standard.integer(forKey: "userBirthYear")
        if savedBirthYear == 0 {
            self.userBirthYear = 2000 // Default birth year
        } else {
            self.userBirthYear = savedBirthYear
        }

        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.hasSeenWelcome = UserDefaults.standard.bool(forKey: "hasSeenWelcome")
        self.hasPlayedWelcomeIntro = UserDefaults.standard.bool(forKey: "hasPlayedWelcomeIntro")

        if let storedBackground = UserDefaults.standard.string(forKey: "chatBackground"),
           let background = ChatBackground(rawValue: storedBackground) {
            self.chatBackground = background
        } else {
            self.chatBackground = .orbit
        }
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}
