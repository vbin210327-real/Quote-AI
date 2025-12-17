//
//  LocalizationManager.swift
//  Quote AI
//
//  Manages in-app language switching
//

import Foundation
import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case spanish = "es"
    case french = "fr"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        }
    }
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
            updateBundle()
        }
    }

    private var bundle: Bundle = Bundle.main

    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .english
        }
        updateBundle()
    }

    private func updateBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            bundle = langBundle
        } else {
            // Fallback to main bundle (English)
            bundle = Bundle.main
        }
    }

    func string(for key: String) -> String {
        return bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }

    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }
}

// Extension for easy localization access
extension String {
    var localized: String {
        return LocalizationManager.shared.string(for: self)
    }
}
