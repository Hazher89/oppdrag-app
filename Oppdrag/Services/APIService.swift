//
//  APIService.swift
//  Oppdrag
//
//  Created by Hazher  on 05/07/2025.
//

import Foundation
import Combine

class APIService: ObservableObject {
    static let shared = APIService()
    
    // Replace with your actual API base URL
    
    private let baseURL = "http://localhost:3000/api/v1"
    private var authToken: String?
    
    private init() {}
    
    // MARK: - Authentication
    func signIn(phoneNumber: String, password: String) async throws -> AuthResponse {
        let endpoint = "/auth/signin"
        let body = SignInRequest(phoneNumber: phoneNumber, password: password)
        
        return try await performRequest(endpoint: endpoint, method: "POST", body: body)
    }
    
    func signUp(phoneNumber: String, name: String, password: String) async throws -> AuthResponse {
        let endpoint = "/auth/signup"
        let body = SignUpRequest(phoneNumber: phoneNumber, name: name, password: password)
        
        return try await performRequest(endpoint: endpoint, method: "POST", body: body)
    }
    
    func forgotPassword(phoneNumber: String) async throws -> ForgotPasswordResponse {
        let endpoint = "/auth/forgot-password"
        let body = ForgotPasswordRequest(phoneNumber: phoneNumber)
        
        return try await performRequest(endpoint: endpoint, method: "POST", body: body)
    }
    
    func resetPassword(phoneNumber: String, resetCode: String, newPassword: String) async throws -> MessageResponse {
        let endpoint = "/auth/reset-password"
        let body = ResetPasswordRequest(phoneNumber: phoneNumber, resetCode: resetCode, newPassword: newPassword)
        
        return try await performRequest(endpoint: endpoint, method: "POST", body: body)
    }
    
    // MARK: - Assignments
    func fetchAssignments() async throws -> [Assignment] {
        let endpoint = "/assignments"
        return try await performRequest(endpoint: endpoint, method: "GET")
    }
    
    func updateAssignmentStatus(assignmentId: String, status: AssignmentStatus) async throws -> Assignment {
        let endpoint = "/assignments/\(assignmentId)/status"
        let body = StatusUpdateRequest(status: status.rawValue)
        return try await performRequest(endpoint: endpoint, method: "PUT", body: body)
    }
    
    func setArrivalTime(assignmentId: String, arrivalTime: Date) async throws -> Assignment {
        let endpoint = "/assignments/\(assignmentId)/arrival-time"
        let body = ArrivalTimeRequest(arrivalTime: ISO8601DateFormatter().string(from: arrivalTime))
        return try await performRequest(endpoint: endpoint, method: "PUT", body: body)
    }
    
    // MARK: - Chat
    func fetchConversations() async throws -> [Conversation] {
        let endpoint = "/chat/conversations"
        return try await performRequest(endpoint: endpoint, method: "GET")
    }
    
    func fetchMessages(conversationId: String) async throws -> [ChatMessage] {
        let endpoint = "/chat/conversations/\(conversationId)/messages"
        return try await performRequest(endpoint: endpoint, method: "GET")
    }
    
    func sendMessage(conversationId: String, content: String) async throws -> ChatMessage {
        let endpoint = "/chat/conversations/\(conversationId)/messages"
        let body = MessageRequest(content: content)
        return try await performRequest(endpoint: endpoint, method: "POST", body: body)
    }
    
    // MARK: - File Upload
    func uploadPDF(assignmentId: String, fileData: Data, fileName: String) async throws -> String {
        let endpoint = "/assignments/\(assignmentId)/pdf"
        
        var request = URLRequest(url: URL(string: baseURL + endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(UUID().uuidString)", forHTTPHeaderField: "Content-Type")
        
        let boundary = UUID().uuidString
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
        
        let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
        return uploadResponse.fileUrl
    }
    
    // MARK: - Generic Request Methods
    private func performRequest<T: Codable>(endpoint: String, method: String) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let authToken = authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError
        default:
            throw APIError.unknown
        }
    }
    
    private func performRequest<T: Codable, U: Codable>(endpoint: String, method: String, body: U) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let authToken = authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError
        default:
            throw APIError.unknown
        }
    }
    
    // MARK: - Token Management
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    func clearAuthToken() {
        self.authToken = nil
    }
}

// MARK: - Request Models
struct SignInRequest: Codable {
    let phoneNumber: String
    let password: String
}

struct SignUpRequest: Codable {
    let phoneNumber: String
    let name: String
    let password: String
}

struct StatusUpdateRequest: Codable {
    let status: String
}

struct ArrivalTimeRequest: Codable {
    let arrivalTime: String
}

struct MessageRequest: Codable {
    let content: String
}

struct ForgotPasswordRequest: Codable {
    let phoneNumber: String
}

struct ResetPasswordRequest: Codable {
    let phoneNumber: String
    let resetCode: String
    let newPassword: String
}

// MARK: - Response Models
struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct ForgotPasswordResponse: Codable {
    let message: String
    let resetCode: String // Remove this in production
    let expiresIn: String
}

struct MessageResponse: Codable {
    let message: String
}

struct UploadResponse: Codable {
    let fileUrl: String
    let fileName: String
}

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError
    case unauthorized
    case notFound
    case serverError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network connection error"
        case .unauthorized:
            return "Unauthorized access"
        case .notFound:
            return "Resource not found"
        case .serverError:
            return "Server error"
        case .unknown:
            return "Unknown error occurred"
        }
    }
} 
