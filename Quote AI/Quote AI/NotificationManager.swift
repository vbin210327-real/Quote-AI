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
        // Cancel existing daily notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_calibration"])
        
        let content = UNMutableNotificationContent()
        content.title = "Quote AI"
        
        // Use appropriate greeting based on scheduled time
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
        content.body = "\(greeting) Time for your daily calibration. Here's a thought for you..."
        content.sound = .default
        
        // Store a random quote in userInfo if needed, or we pick one on launch
        let randomQuote = fallbackQuotes.randomElement() ?? ""
        content.userInfo = ["quote": randomQuote]
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_calibration", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
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
