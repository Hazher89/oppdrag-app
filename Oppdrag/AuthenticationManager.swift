//
//  AuthenticationManager.swift
//  Oppdrag
//
//  Created by Hazher  on 05/07/2025.
//

import Foundation
import SwiftUI

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Authentication Methods
    
    func signIn(phoneNumber: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        // Simulate API call with demo data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // For demo purposes, accept any phone number with password "123456"
            if password == "123456" {
                self.currentUser = User(
                    id: UUID().uuidString,
                    phoneNumber: phoneNumber,
                    name: "Driver \(phoneNumber.suffix(4))",
                    role: .driver,
                    companyId: "demo_company"
                )
                self.isAuthenticated = true
            } else {
                self.errorMessage = "Invalid credentials"
            }
            self.isLoading = false
        }
    }
    
    func signUp(phoneNumber: String, name: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        // Simulate API call with demo data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.currentUser = User(
                id: UUID().uuidString,
                phoneNumber: phoneNumber,
                name: name,
                role: .driver,
                companyId: "demo_company"
            )
            self.isAuthenticated = true
            self.isLoading = false
        }
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
    }
}

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: String
    let phoneNumber: String
    let name: String
    let role: UserRole
    let companyId: String
}

enum UserRole: String, CaseIterable, Codable {
    case driver = "driver"
    case admin = "admin"
    
    var displayName: String {
        switch self {
        case .driver:
            return "Driver"
        case .admin:
            return "Administrator"
        }
    }
} 