import Foundation
import UserNotifications
import SwiftUI
import Combine

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var selectedDailyQuote: String?
    @Published var showDailyQuoteOverlay = false
    
    // Sample quotes for daily calibration if we can't fetch from AI in background easily
    private let fallbackQuotes = [
        "The best way to predict the future is to create it.",
        "Your only limit is your soul.",
        "Focus on the step, not the mountain.",
        "Silence is sometimes the loudest answer.",
        "Energy flows where intention goes."
    ]

    private let dailyNotificationId = "daily_calibration"
    private let dailyNotificationImmediateId = "daily_calibration_immediate"
    private let dailyNotificationQuoteKey = "dailyNotificationQuote"
    
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkPermissionStatus()
    }
    
    func checkPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.permissionStatus = settings.authorizationStatus
            }
        }
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            self.checkPermissionStatus()
            if granted {
                // Use user's saved notification time
                DispatchQueue.main.async {
                    let hour = UserPreferences.shared.notificationHour
                    let minute = UserPreferences.shared.notificationMinute
                    self.scheduleDailyNotification(at: hour, minute: minute)
                }
            }
        }
    }
    
    func scheduleDailyNotification(at hour: Int = 8, minute: Int = 0) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyNotificationId, dailyNotificationImmediateId])

        let cachedQuote = cachedDailyNotificationQuote()
        let quote = cachedQuote ?? fallbackQuotes.randomElement() ?? "Take a breath and begin again."
        Task { @MainActor in
            await scheduleDailyNotificationContent(quote: quote, at: hour, minute: minute)
            await scheduleImmediateNotificationIfNeeded(quote: quote, at: hour, minute: minute)
        }

        Task {
            await refreshDailyNotificationQuoteIfNeeded(at: hour, minute: minute)
        }
    }

    @MainActor
    private func scheduleDailyNotificationContent(quote: String, at hour: Int, minute: Int) async {
        let content = makeNotificationContent(quote: quote, hour: hour, minute: minute)

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: dailyNotificationId, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("[NotificationManager] Failed to schedule daily notification: \(error)")
        }
    }

    @MainActor
    private func scheduleImmediateNotificationIfNeeded(quote: String, at hour: Int, minute: Int) async {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard let selectedToday = calendar.date(from: components) else { return }
        let delta = selectedToday.timeIntervalSince(now)

        guard delta <= 0, delta > -60 else { return }

        let content = makeNotificationContent(quote: quote, hour: hour, minute: minute)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: dailyNotificationImmediateId, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("[NotificationManager] Failed to schedule immediate notification: \(error)")
        }
    }

    private func refreshDailyNotificationQuoteIfNeeded(at hour: Int, minute: Int) async {
        guard isProUser() else { return }

        let nextTrigger = nextTriggerDate(hour: hour, minute: minute)
        let timeUntilTrigger = nextTrigger.timeIntervalSinceNow

        do {
            let newQuote = try await KimiService.shared.generateGeneralDailyQuote()
            cacheDailyNotificationQuote(newQuote)

            if timeUntilTrigger > 60 {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyNotificationId])
                await scheduleDailyNotificationContent(quote: newQuote, at: hour, minute: minute)
            }
        } catch {
            // Keep the existing scheduled quote if AI fetch fails.
        }
    }

    private func nextTriggerDate(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute

        let todayTrigger = calendar.date(from: components) ?? Date()
        if todayTrigger > Date() {
            return todayTrigger
        }
        return calendar.date(byAdding: .day, value: 1, to: todayTrigger) ?? todayTrigger
    }

    private func cachedDailyNotificationQuote() -> String? {
        UserDefaults.standard.string(forKey: dailyNotificationQuoteKey)
    }

    private func cacheDailyNotificationQuote(_ quote: String) {
        UserDefaults.standard.set(quote, forKey: dailyNotificationQuoteKey)
    }

    @MainActor
    private func makeNotificationContent(quote: String, hour: Int, minute: Int) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Quote AI"

        let userName = UserPreferences.shared.userName
        let timeGreeting: String
        switch hour {
        case 5..<12:
            timeGreeting = "Good morning"
        case 12..<18:
            timeGreeting = "Good afternoon"
        default:
            timeGreeting = "Good evening"
        }
        let greeting = userName.isEmpty ? "\(timeGreeting)." : "\(timeGreeting), \(userName)."
        content.body = "\(greeting) Time for your daily quotes."
        content.sound = .default
        content.userInfo = ["quote": quote]
        return content
    }

    private func isProUser() -> Bool {
        let sharedDefaults = UserDefaults(suiteName: SharedConstants.suiteName)
        return sharedDefaults?.bool(forKey: SharedConstants.Keys.isProUser) ?? false
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Don't show notification banner when app is in foreground
        // This prevents the notification from appearing again if the user is already in the app
        completionHandler([])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Remove the delivered notification from Notification Center to prevent it from appearing again
        let notificationId = response.notification.request.identifier
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notificationId])
        
        if let quote = userInfo["quote"] as? String {
            DispatchQueue.main.async {
                self.selectedDailyQuote = quote
                withAnimation(.spring()) {
                    self.showDailyQuoteOverlay = true
                }
            }
        }
        
        completionHandler()
    }
}
