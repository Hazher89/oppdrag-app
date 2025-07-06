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
    private let apiService = APIService()
    
    // MARK: - Authentication Methods
    
    // MARK: - Email Verification Methods
    
    func sendVerificationCode(email: String, type: String) async throws -> VerificationResponse {
        let response: VerificationResponse = try await apiService.performRequest(
            endpoint: "/auth/send-verification-code",
            method: "POST",
            body: SendVerificationRequest(email: email, type: type)
        )
        return response
    }
    
    func verifyCode(email: String, verificationCode: String, type: String, name: String? = nil, password: String? = nil) async throws {
        var body: [String: Any] = [
            "email": email,
            "verificationCode": verificationCode,
            "type": type
        ]
        
        if type == "registration" {
            guard let name = name, let password = password else {
                throw AuthError.missingRegistrationData
            }
            body["name"] = name
            body["password"] = password
            body["companyId"] = "demo_company" // Default company for demo
            body["role"] = "driver" // Default role for demo
        }
        
        let response: AuthResponse = try await apiService.performRequest(
            endpoint: "/auth/verify-code",
            method: "POST",
            body: body
        )
        
        await MainActor.run {
            self.currentUser = response.user
            self.isAuthenticated = true
            self.apiService.setAuthToken(response.token)
        }
    }
    
    // MARK: - Legacy Methods (for backward compatibility)
    
    func signIn(email: String, password: String) {
        // This method is now deprecated - use email verification instead
        isLoading = true
        errorMessage = nil
        
        // Simulate API call with demo data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // For demo purposes, accept any email with password "123456"
            if password == "123456" {
                self.currentUser = User(
                    id: UUID().uuidString,
                    email: email,
                    name: "Driver \(email.prefix(4))",
                    role: .driver,
                    companyId: "demo_company",
                    isEmailVerified: true
                )
                self.isAuthenticated = true
            } else {
                self.errorMessage = "Invalid credentials"
            }
            self.isLoading = false
        }
    }
    
    func signUp(email: String, name: String, password: String) {
        // This method is now deprecated - use email verification instead
        isLoading = true
        errorMessage = nil
        
        // Simulate API call with demo data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.currentUser = User(
                id: UUID().uuidString,
                email: email,
                name: name,
                role: .driver,
                companyId: "demo_company",
                isEmailVerified: true
            )
            self.isAuthenticated = true
            self.isLoading = false
        }
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        apiService.clearAuthToken()
    }
}

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: String
    let email: String
    let name: String
    let role: UserRole
    let companyId: String
    let isEmailVerified: Bool?
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

// MARK: - Email Verification Models

struct SendVerificationRequest: Codable {
    let email: String
    let type: String
}

struct VerificationResponse: Codable {
    let message: String
    let email: String
    let type: String
    let expiresIn: String
}

// AuthResponse is now defined in APIService.swift

enum AuthError: Error, LocalizedError {
    case missingRegistrationData
    case invalidVerificationCode
    case verificationCodeExpired
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .missingRegistrationData:
            return "Missing registration data"
        case .invalidVerificationCode:
            return "Invalid verification code"
        case .verificationCodeExpired:
            return "Verification code has expired"
        case .networkError:
            return "Network error occurred"
        }
    }
} 