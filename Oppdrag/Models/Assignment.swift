import Foundation
import CoreData
import SwiftUI

struct Assignment: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let date: Date
    var status: AssignmentStatus
    let pdfUrl: String
    var arrivalTime: Date?
}

// REVERT to previous Assignment model and AssignmentStatus enum
// Remove DriverAssignment, DriverAssignmentStatus, dueDate, and related changes
// Restore Assignment struct and AssignmentStatus enum as before

// Assignment status enum
enum AssignmentStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .cancelled:
            return .red
        }
    }
}

// API Response structures
struct AssignmentResponse: Codable {
    let success: Bool
    let data: [Assignment]
    let message: String?
}

struct SingleAssignmentResponse: Codable {
    let success: Bool
    let data: Assignment
    let message: String?
}

struct CreateAssignmentRequest: Codable {
    let title: String
    let description: String?
    let dueDate: Date?
    let arrivalTime: Date?
    let driverId: String?
    let pdfUrl: String?
}

struct UpdateAssignmentRequest: Codable {
    let title: String?
    let description: String?
    let status: String?
    let dueDate: Date?
    let arrivalTime: Date?
    let pdfUrl: String?
} 