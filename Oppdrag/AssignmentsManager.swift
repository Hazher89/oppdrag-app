//
//  AssignmentsManager.swift
//  Oppdrag
//
//  Created by Hazher  on 05/07/2025.
//

import Foundation
import SwiftUI

class AssignmentsManager: ObservableObject {
    @Published var assignments: [Assignment] = []
    @Published var isLoading = false
    
    func loadAssignments() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            // Demo data
            assignments = [
                Assignment(
                    id: "1",
                    title: "Morning Route - Downtown",
                    description: "Deliver packages to downtown area. Start at warehouse and follow route map.",
                    date: Date().addingTimeInterval(86400), // Tomorrow
                    status: .pending,
                    pdfUrl: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
                    arrivalTime: nil
                ),
                Assignment(
                    id: "2",
                    title: "Afternoon Route - Suburbs",
                    description: "Pick up and deliver items in suburban areas. Check in at each location.",
                    date: Date().addingTimeInterval(172800), // Day after tomorrow
                    status: .inProgress,
                    pdfUrl: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
                    arrivalTime: Date().addingTimeInterval(3600)
                ),
                Assignment(
                    id: "3",
                    title: "Special Delivery - Airport",
                    description: "Urgent delivery to airport cargo area. Priority handling required.",
                    date: Date().addingTimeInterval(259200),
                    status: .completed,
                    pdfUrl: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
                    arrivalTime: Date().addingTimeInterval(-3600)
                )
            ]
            isLoading = false
        }
    }
    
    func updateArrivalTime(for assignmentId: String, time: Date) async {
        await MainActor.run {
            if let index = assignments.firstIndex(where: { $0.id == assignmentId }) {
                assignments[index].arrivalTime = time
                assignments[index].status = .inProgress
            }
        }
    }
    
    func markAssignmentComplete(assignmentId: String) async {
        await MainActor.run {
            if let index = assignments.firstIndex(where: { $0.id == assignmentId }) {
                assignments[index].status = .completed
            }
        }
    }
}

// MARK: - Assignment Model
struct Assignment: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let date: Date
    var status: AssignmentStatus
    let pdfUrl: String
    var arrivalTime: Date?
}

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