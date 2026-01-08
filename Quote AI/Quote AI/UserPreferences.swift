//
//  UserPreferences.swift
//  Quote AI
//
//  Manages user personalization settings
//

import Foundation
import Combine
import UserNotifications

extension QuoteTone {
    var displayName: String {
        return localizedName
    }

    var localizedName: String {
        switch self {
        case .motivational: return LocalizationManager.shared.string(for: "tone.motivational")
        case .naval: return LocalizationManager.shared.string(for: "tone.naval")
        case .philosophical: return LocalizationManager.shared.string(for: "tone.philosophical")
        case .realist: return LocalizationManager.shared.string(for: "tone.realist")
        }
    }
    
    var icon: String {
        switch self {
        case .motivational: return "bolt.fill"
        case .naval: return "lightbulb.fill"
        case .philosophical: return "brain.head.profile"
        case .realist: return "chart.line.uptrend.xyaxis"
        }
    }
}

extension UserFocus {
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

extension UserBarrier {
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

extension UserEnergyDrain {
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
    case unknown = "Unknown"
    case genAlpha = "Gen Alpha"       // 2013-2024
    case genZ = "Gen Z"               // 1997-2012
    case millennial = "Millennial"    // 1981-1996
    case genX = "Gen X"               // 1965-1980
    case boomer = "Baby Boomer"       // 1946-1964
    case silent = "Silent Generation" // Before 1946

    static func from(birthYear: Int) -> UserGeneration {
        let currentYear = Calendar.current.component(.year, from: Date())
        if birthYear <= 0 {
            return .unknown
        }
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
        case .unknown:
            return "Keep the language broadly accessible and neutral."
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
        case .unknown: return "Unknown"
        case .genAlpha: return "2013-present"
        case .genZ: return "1997-2012"
        case .millennial: return "1981-1996"
        case .genX: return "1965-1980"
        case .boomer: return "1946-1964"
        case .silent: return "Before 1946"
        }
    }
}

extension ChatBackground {
    var icon: String {
        switch self {
        case .summit: return "mountain.2"
        case .ascent: return "list.bullet.indent"
        case .dawnRun: return "figure.run"
        case .defaultBackground: return "square.grid.2x2"
        }
    }

    var assetName: String {
        switch self {
        case .summit: return "ChatBackgroundSummit"
        case .ascent: return "ChatBackgroundStairs"
        case .dawnRun: return "ChatBackgroundDawnRun"
        case .defaultBackground: return "default_background"
        }
    }

    var displayName: String {
        switch self {
        case .summit: return "Icy Peak"
        case .ascent: return "Shadow Staircase"
        case .dawnRun: return "Dawn Run"
        case .defaultBackground: return "Default"
        }
    }

    var localizedName: String {
        switch self {
        case .summit: return LocalizationManager.shared.string(for: "background.summit")
        case .ascent: return LocalizationManager.shared.string(for: "background.ascent")
        case .dawnRun: return LocalizationManager.shared.string(for: "background.dawnRun")
        case .defaultBackground: return LocalizationManager.shared.string(for: "background.default")
        }
    }

    var description: String {
        switch self {
        case .summit: return ""
        case .ascent: return ""
        case .dawnRun: return ""
        case .defaultBackground: return ""
        }
    }
}

class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    /// Cloud profile image URL (stored in Supabase)
    @Published var profileImageUrl: String? {
        didSet {
            UserDefaults.standard.set(profileImageUrl, forKey: "profileImageUrl")
        }
    }

    @Published var userName: String {
        didSet {
            UserDefaults.standard.set(userName, forKey: "userName")
            syncToCloudDebounced()
        }
    }

    @Published var profileImage: Data? {
        didSet {
            // Only act if the data actually changed to avoid redundant work and UI flickering
            guard profileImage != oldValue else { return }
            
            print("[ProfileImage] didSet called, size: \(profileImage?.count ?? 0) bytes")
            
            // Save to disk immediately
            UserDefaults.standard.set(profileImage, forKey: "userProfileImage")
            UserDefaults.standard.synchronize()
            
            // Wrap in MainActor and async to avoid SwiftUI List warnings (cell visiting errors)
            Task { @MainActor in
                if !isSyncingFromCloud {
                    if let data = profileImage, data.count > 0 {
                        // New image: Upload it
                        uploadProfileImageToCloud()
                    } else if profileImage == nil {
                        // Image cleared: Update URL and sync to cloud
                        print("[ProfileImage] Image cleared, updating URL")
                        profileImageUrl = nil
                        await syncToCloud()
                    }
                }
            }
        }
    }

    @Published var userGender: String {
        didSet {
            UserDefaults.standard.set(userGender, forKey: "userGender")
            syncToCloudDebounced()
        }
    }

    @Published var quoteTone: QuoteTone {
        didSet {
            UserDefaults.standard.set(quoteTone.rawValue, forKey: "quoteTone")
            UserDefaults.standard.synchronize()
            updateSharedDefaults(key: SharedConstants.Keys.quoteTone, value: quoteTone.rawValue)
            syncToCloudImmediate()
        }
    }

    @Published var userFocus: UserFocus {
        didSet {
            UserDefaults.standard.set(userFocus.rawValue, forKey: "userFocus")
            UserDefaults.standard.synchronize()
            syncToCloudDebounced()
        }
    }

    @Published var userBarrier: UserBarrier {
        didSet {
            UserDefaults.standard.set(userBarrier.rawValue, forKey: "userBarrier")
            UserDefaults.standard.synchronize()
            updateSharedDefaults(key: SharedConstants.Keys.userBarrier, value: userBarrier.rawValue)
            syncToCloudDebounced()
        }
    }

    @Published var userEnergyDrain: UserEnergyDrain {
        didSet {
            UserDefaults.standard.set(userEnergyDrain.rawValue, forKey: "userEnergyDrain")
            UserDefaults.standard.synchronize()
            syncToCloudDebounced()
        }
    }

    @Published var mentalEnergy: Double {
        didSet {
            UserDefaults.standard.set(mentalEnergy, forKey: "mentalEnergy")
            syncToCloudDebounced()
        }
    }

    @Published var userBirthYear: Int {
        didSet {
            UserDefaults.standard.set(userBirthYear, forKey: "userBirthYear")
            syncToCloudDebounced()
        }
    }

    var userGeneration: UserGeneration {
        return UserGeneration.from(birthYear: userBirthYear)
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
            syncToCloudDebounced()
        }
    }

    @Published var shouldSkipOnboardingSignIn: Bool = false

    @Published var hasSeenWelcome: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenWelcome, forKey: "hasSeenWelcome")
        }
    }

    @Published var hasPlayedWelcomeIntro: Bool {
        didSet {
            UserDefaults.standard.set(hasPlayedWelcomeIntro, forKey: "hasPlayedWelcomeIntro")
            UserDefaults.standard.synchronize() // Force immediate save
        }
    }

    @Published var chatBackground: ChatBackground {
        didSet {
            UserDefaults.standard.set(chatBackground.rawValue, forKey: "chatBackground")
            UserDefaults.standard.synchronize()
            syncToCloudImmediate()
        }
    }

    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
            syncToCloudDebounced()
            if notificationsEnabled {
                NotificationManager.shared.requestPermission()
            } else {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_calibration", "daily_calibration_immediate"])
            }
        }
    }

    private var notificationScheduleTask: Task<Void, Never>?

    @Published var notificationHour: Int {
        didSet {
            UserDefaults.standard.set(notificationHour, forKey: "notificationHour")
            syncToCloudDebounced()
            if notificationsEnabled {
                scheduleDailyNotificationDebounced()
            }
        }
    }

    @Published var notificationMinute: Int {
        didSet {
            UserDefaults.standard.set(notificationMinute, forKey: "notificationMinute")
            syncToCloudDebounced()
            if notificationsEnabled {
                scheduleDailyNotificationDebounced()
            }
        }
    }

    private func scheduleDailyNotificationDebounced() {
        notificationScheduleTask?.cancel()
        notificationScheduleTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 800_000_000)
            NotificationManager.shared.scheduleDailyNotification(at: notificationHour, minute: notificationMinute)
        }
    }

    /// Flag to prevent sync during initial load from cloud
    private var isSyncingFromCloud = false
    /// Flag to prevent syncFromCloud from overwriting a new local image while it's uploading
    private var isUploadingProfileImage = false
    private var syncTask: Task<Void, Never>?
    private init() {
        self.profileImageUrl = UserDefaults.standard.string(forKey: "profileImageUrl")
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        self.profileImage = UserDefaults.standard.data(forKey: "userProfileImage")
        self.userGender = UserDefaults.standard.string(forKey: "userGender") ?? ""

        if let toneString = UserDefaults.standard.string(forKey: "quoteTone"),
           let tone = QuoteTone.fromStoredValue(toneString) {
            self.quoteTone = tone
        } else {
            self.quoteTone = .naval
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
        self.userBirthYear = savedBirthYear

        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.hasSeenWelcome = UserDefaults.standard.bool(forKey: "hasSeenWelcome")
        self.hasPlayedWelcomeIntro = UserDefaults.standard.bool(forKey: "hasPlayedWelcomeIntro")

        if let storedBackground = UserDefaults.standard.string(forKey: "chatBackground"),
           let background = ChatBackground(rawValue: storedBackground) {
            self.chatBackground = background
        } else {
            self.chatBackground = .defaultBackground
        }

        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.notificationHour = UserDefaults.standard.integer(forKey: "notificationHour") == 0 && !UserDefaults.standard.bool(forKey: "notificationSet") ? 8 : UserDefaults.standard.integer(forKey: "notificationHour")
        self.notificationMinute = UserDefaults.standard.integer(forKey: "notificationMinute")

        print("[ProfileImage] Init loaded from UserDefaults, size: \(self.profileImage?.count ?? 0) bytes")
        print("[ProfileImage] Init profileImageUrl: \(self.profileImageUrl ?? "nil")")
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
    }

    // MARK: - Cloud Sync

    /// Sync current preferences to cloud
    func syncToCloudImmediate() {
        guard !isSyncingFromCloud else { return }
        Task { @MainActor in
            await syncToCloud()
        }
    }

    /// Debounced sync to avoid excessive API calls
    private func syncToCloudDebounced() {
        guard !isSyncingFromCloud else { return }

        syncTask?.cancel()
        syncTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // Shorter 0.3 second debounce
            guard !Task.isCancelled else { return }
            await syncToCloud()
        }
    }

    /// Flush any pending sync immediately (called when app goes to background)
    @MainActor
    func flushPendingSync() async {
        // Cancel the debounced task and sync immediately
        syncTask?.cancel()
        syncTask = nil
        await syncToCloud()
    }

    /// Upload profile image to cloud storage
    private func uploadProfileImageToCloud() {
        print("[ProfileImage] uploadProfileImageToCloud called")
        guard !isSyncingFromCloud else {
            print("[ProfileImage] Skipped: isSyncingFromCloud is true")
            return
        }
        guard let imageData = profileImage, imageData.count > 0 else {
            print("[ProfileImage] Skipped: profileImage is nil or empty")
            return
        }
        
        isUploadingProfileImage = true
        print("[ProfileImage] Starting upload, image size: \(imageData.count) bytes")

        Task { @MainActor in
            defer { isUploadingProfileImage = false }
            do {
                let url = try await SupabaseManager.shared.uploadProfileImage(imageData: imageData)
                print("[ProfileImage] Upload success! URL: \(url)")
                self.profileImageUrl = url
                await syncToCloud()
            } catch {
                print("[ProfileImage] Upload FAILED: \(error)")
            }
        }
    }

    /// Sync current preferences to cloud
    @MainActor
    func syncToCloud() async {
        guard !isSyncingFromCloud else { return }
        guard SupabaseManager.shared.isAuthenticated else { return }

        do {
            try await SupabaseManager.shared.saveUserProfile(
                name: userName.isEmpty ? nil : userName,
                gender: userGender.isEmpty ? nil : userGender,
                profileImageUrl: profileImageUrl,
                birthYear: userBirthYear == 0 ? nil : userBirthYear,
                quoteTone: quoteTone.rawValue,
                userFocus: userFocus.rawValue,
                userBarrier: userBarrier.rawValue,
                energyDrain: userEnergyDrain.rawValue,
                mentalEnergy: mentalEnergy,
                chatBackground: chatBackground.rawValue,
                notificationsEnabled: notificationsEnabled,
                notificationHour: notificationHour,
                notificationMinute: notificationMinute,
                language: LocalizationManager.shared.currentLanguage.rawValue,
                hasCompletedOnboarding: hasCompletedOnboarding
            )
        } catch {
            print("Failed to sync profile to cloud: \(error)")
        }
    }

    /// Load preferences from cloud (called on login)
    @MainActor
    func syncFromCloud() async {
        guard SupabaseManager.shared.isAuthenticated else { return }

        isSyncingFromCloud = true
        defer { isSyncingFromCloud = false }

        do {
            guard let profile = try await SupabaseManager.shared.fetchUserProfile() else {
                // No cloud profile exists, upload current local settings
                await syncToCloud()
                return
            }

            // Apply cloud data to local (cloud wins ONLY if different)
            if let name = profile.name, name != userName {
                userName = name
            }
            if let gender = profile.gender, gender != userGender {
                userGender = gender
            }
            if let imageUrl = profile.profileImageUrl, imageUrl != profileImageUrl {
                // DON'T download if we are currently uploading a new image!
                if isUploadingProfileImage {
                    print("[ProfileImage] syncFromCloud: Skipped download because an upload is in progress")
                } else {
                    print("[ProfileImage] syncFromCloud: Cloud URL different, downloading from: \(imageUrl)")
                    profileImageUrl = imageUrl
                    // Download and cache the image locally
                    if let imageData = try await SupabaseManager.shared.downloadProfileImage(from: imageUrl) {
                        print("[ProfileImage] syncFromCloud: Downloaded \(imageData.count) bytes")
                        profileImage = imageData
                    } else {
                        print("[ProfileImage] syncFromCloud: Download returned nil")
                    }
                }
            } else if profile.profileImageUrl == nil && profileImageUrl != nil {
                // Cloud has no image, but we do: Clear local if we're not currently uploading
                if !isUploadingProfileImage {
                    print("[ProfileImage] syncFromCloud: Cloud cleared image, clearing locally")
                    profileImageUrl = nil
                    profileImage = nil
                }
            } else {
                print("[ProfileImage] syncFromCloud: URL unchanged or both nil, skipping download")
            }
            if let birthYear = profile.birthYear, birthYear != userBirthYear {
                userBirthYear = birthYear
            }
            if let tone = profile.quoteTone, let quoteToneValue = QuoteTone.fromStoredValue(tone), quoteToneValue != quoteTone {
                quoteTone = quoteToneValue
            }
            if let focus = profile.userFocus, let focusValue = UserFocus(rawValue: focus), focusValue != userFocus {
                userFocus = focusValue
            }
            if let barrier = profile.userBarrier, let barrierValue = UserBarrier(rawValue: barrier), barrierValue != userBarrier {
                userBarrier = barrierValue
            }
            if let drain = profile.energyDrain, let drainValue = UserEnergyDrain(rawValue: drain), drainValue != userEnergyDrain {
                userEnergyDrain = drainValue
            }
            if let energy = profile.mentalEnergy, energy != mentalEnergy {
                mentalEnergy = energy
            }
            if let background = profile.chatBackground, let bgValue = ChatBackground(rawValue: background), bgValue != chatBackground {
                chatBackground = bgValue
            }
            if let language = profile.language, let langValue = AppLanguage(rawValue: language), langValue != LocalizationManager.shared.currentLanguage {
                LocalizationManager.shared.setLanguageFromCloud(langValue)
            }
            if let onboarding = profile.hasCompletedOnboarding {
                if onboarding != hasCompletedOnboarding {
                    hasCompletedOnboarding = onboarding
                }
            } else if !hasCompletedOnboarding {
                // Legacy profiles without this flag should skip onboarding.
                hasCompletedOnboarding = true
            }
            if let notifEnabled = profile.notificationsEnabled, notifEnabled != notificationsEnabled {
                notificationsEnabled = notifEnabled
            }
            if let hour = profile.notificationHour, hour != notificationHour {
                notificationHour = hour
            }
            if let minute = profile.notificationMinute, minute != notificationMinute {
                notificationMinute = minute
            }
        } catch {
            print("Failed to sync profile from cloud: \(error)")
        }
    }

    /// Clear local data on logout
    func clearLocalData() {
        userName = ""
        userGender = ""
        profileImage = nil
        profileImageUrl = nil
        quoteTone = .naval
        userFocus = .innerPeace
        userBarrier = .procrastination
        userEnergyDrain = .career
        mentalEnergy = 0.5
        userBirthYear = 0
        hasCompletedOnboarding = false
        shouldSkipOnboardingSignIn = false
        hasSeenWelcome = false
        // Note: hasPlayedWelcomeIntro is intentionally NOT reset here
        // The welcome animation should only play once ever, even after logout
        chatBackground = .defaultBackground
    }
    private func updateSharedDefaults(key: String, value: String) {
        if let sharedDefaults = UserDefaults(suiteName: SharedConstants.suiteName) {
            sharedDefaults.set(value, forKey: key)
            sharedDefaults.synchronize()
        }
    }
}
