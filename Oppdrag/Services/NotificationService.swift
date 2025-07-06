//
//  NotificationService.swift
//  Oppdrag
//
//  Created by Hazher  on 05/07/2025.
//

import Foundation
import UserNotifications
import UIKit

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Request Permission
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            
            if granted {
                await registerForRemoteNotifications()
            }
            
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    // MARK: - Register for Remote Notifications
    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Local Notifications
    func scheduleAssignmentNotification(assignment: Assignment) {
        let content = UNMutableNotificationContent()
        content.title = "New Assignment"
        content.body = "You have a new assignment: \(assignment.title)"
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "assignment",
            "assignmentId": assignment.id
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "assignment-\(assignment.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleChatNotification(conversation: Conversation, message: String) {
        let content = UNMutableNotificationContent()
        content.title = conversation.title
        content.body = message
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "chat",
            "conversationId": conversation.id
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "chat-\(conversation.id)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleArrivalReminder(assignment: Assignment, arrivalTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Arrival Reminder"
        content.body = "Your assignment '\(assignment.title)' starts in 30 minutes"
        content.sound = .default
        content.userInfo = [
            "type": "reminder",
            "assignmentId": assignment.id
        ]
        
        let reminderTime = arrivalTime.addingTimeInterval(-1800) // 30 minutes before
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "reminder-\(assignment.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Clear Notifications
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func clearAssignmentNotifications(assignmentId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["assignment-\(assignmentId)"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["assignment-\(assignmentId)"])
    }
    
    // MARK: - Handle Remote Notification Token
    func handleDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device token: \(tokenString)")
        
        // Send token to your backend
        Task {
            await sendTokenToServer(tokenString)
        }
    }
    
    private func sendTokenToServer(_ token: String) async {
        // Implement sending token to your backend
        // This should be called after user authentication
        print("Sending device token to server: \(token)")
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification tap
        if let type = userInfo["type"] as? String {
            switch type {
            case "assignment":
                if let assignmentId = userInfo["assignmentId"] as? String {
                    // Navigate to assignment detail
                    handleAssignmentNotification(assignmentId: assignmentId)
                }
            case "chat":
                if let conversationId = userInfo["conversationId"] as? String {
                    // Navigate to chat
                    handleChatNotification(conversationId: conversationId)
                }
            case "reminder":
                if let assignmentId = userInfo["assignmentId"] as? String {
                    // Navigate to assignment detail
                    handleAssignmentNotification(assignmentId: assignmentId)
                }
            default:
                break
            }
        }
        
        completionHandler()
    }
    
    private func handleAssignmentNotification(assignmentId: String) {
        // Post notification to navigate to assignment
        NotificationCenter.default.post(
            name: .navigateToAssignment,
            object: nil,
            userInfo: ["assignmentId": assignmentId]
        )
    }
    
    private func handleChatNotification(conversationId: String) {
        // Post notification to navigate to chat
        NotificationCenter.default.post(
            name: .navigateToChat,
            object: nil,
            userInfo: ["conversationId": conversationId]
        )
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let navigateToAssignment = Notification.Name("navigateToAssignment")
    static let navigateToChat = Notification.Name("navigateToChat")
} 