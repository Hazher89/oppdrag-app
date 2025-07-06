//
//  OppdragApp.swift
//  Oppdrag
//
//  Created by Hazher  on 05/07/2025.
//

import SwiftUI
import UserNotifications

@main
struct OppdragApp: App {
    @StateObject private var notificationService = NotificationService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationService)
                .onAppear {
                    setupNotifications()
                }
        }
    }
    
    private func setupNotifications() {
        Task {
            await notificationService.requestPermission()
        }
    }
}
