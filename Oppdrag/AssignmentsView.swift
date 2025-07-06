//
//  AssignmentsView.swift
//  Oppdrag
//
//  Created by Hazher  on 05/07/2025.
//

import SwiftUI

struct AssignmentsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var assignmentsManager = AssignmentsManager()
    @State private var showingAssignmentDetail = false
    @State private var selectedAssignment: Assignment?
    
    var body: some View {
        NavigationView {
            VStack {
                if assignmentsManager.assignments.isEmpty {
                    EmptyStateView()
                } else {
                    List(assignmentsManager.assignments) { assignment in
                        AssignmentRowView(assignment: assignment) {
                            selectedAssignment = assignment
                            showingAssignmentDetail = true
                        }
                    }
                    .refreshable {
                        await assignmentsManager.loadAssignments()
                    }
                }
            }
            .navigationTitle("Assignments")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAssignmentDetail) {
                if let assignment = selectedAssignment {
                    AssignmentDetailView(assignment: assignment)
                }
            }
            .task {
                await assignmentsManager.loadAssignments()
            }
        }
    }
}

struct AssignmentRowView: View {
    let assignment: Assignment
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(assignment.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(assignment.date, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(assignment.status.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(assignment.status.color.opacity(0.2))
                            .foregroundColor(assignment.status.color)
                            .cornerRadius(8)
                        
                        if let arrivalTime = assignment.arrivalTime {
                            Text("Arrival: \(arrivalTime, style: .time)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if !assignment.description.isEmpty {
                    Text(assignment.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Assignments")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your assignments will appear here when they are assigned to you.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AssignmentsView()
        .environmentObject(AuthenticationManager())
} 