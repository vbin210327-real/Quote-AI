//
//  LocalizationManager.swift
//  Quote AI
//
//  Manages in-app language switching
//

import Foundation
import SwiftUI
import Combine

extension AppLanguage {
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .chinese: return "中文"
        case .hindi: return "हिन्दी"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .chinese: return "🇨🇳"
        case .hindi: return "🇮🇳"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        }
    }
    var locale: Locale {
        return Locale(identifier: self.rawValue)
    }
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
            // Also save to shared UserDefaults for widget
            if let sharedDefaults = UserDefaults(suiteName: SharedConstants.suiteName) {
                sharedDefaults.set(currentLanguage.rawValue, forKey: SharedConstants.Keys.appLanguage)
            }
            updateBundle()
            // Sync language change to cloud
            if !isSyncingFromCloud {
                syncLanguageToCloud()
            }
        }
    }

    private var bundle: Bundle = Bundle.main
    private var isSyncingFromCloud = false

    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .english
        }
        // Sync to shared UserDefaults for widget
        if let sharedDefaults = UserDefaults(suiteName: SharedConstants.suiteName) {
            sharedDefaults.set(currentLanguage.rawValue, forKey: SharedConstants.Keys.appLanguage)
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

    /// Set language from cloud sync (doesn't trigger sync back)
    func setLanguageFromCloud(_ language: AppLanguage) {
        isSyncingFromCloud = true
        currentLanguage = language
        isSyncingFromCloud = false
    }

    private func syncLanguageToCloud() {
        Task { @MainActor in
            await UserPreferences.shared.syncToCloud()
        }
    }
}

// Extension for easy localization access
extension String {
    var localized: String {
        return LocalizationManager.shared.string(for: self)
    }
}
