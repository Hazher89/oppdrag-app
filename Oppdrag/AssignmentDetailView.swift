//
//  AssignmentDetailView.swift
//  Oppdrag
//
//  Created by Hazher  on 05/07/2025.
//

import SwiftUI

struct AssignmentDetailView: View {
    let assignment: Assignment
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assignmentsManager = AssignmentsManager()
    @State private var showingArrivalTimePicker = false
    @State private var selectedArrivalTime = Date()
    @State private var showingPDF = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(assignment.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text(assignment.status.displayName)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(assignment.status.color.opacity(0.2))
                                .foregroundColor(assignment.status.color)
                                .cornerRadius(12)
                        }
                        
                        Text(assignment.date, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(assignment.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // PDF Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Assignment Details")
                            .font(.headline)
                        
                        Button(action: { showingPDF = true }) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("View Assignment PDF")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Text("Tap to open assignment details")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    // Arrival Time Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Arrival Time")
                            .font(.headline)
                        
                        if let arrivalTime = assignment.arrivalTime {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Set for: \(arrivalTime, style: .time)")
                                        .font(.body)
                                    
                                    Text("Arrival time confirmed")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        } else {
                            Button(action: { showingArrivalTimePicker = true }) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.blue)
                                    
                                    Text("Set Arrival Time")
                                        .font(.body)
                                        .foregroundColor(.blue)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    if assignment.status == .pending || assignment.status == .inProgress {
                        VStack(spacing: 12) {
                            if assignment.status == .pending {
                                Button(action: markInProgress) {
                                    HStack {
                                        Image(systemName: "play.fill")
                                        Text("Start Assignment")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                            
                            if assignment.status == .inProgress {
                                Button(action: markComplete) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Mark Complete")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Assignment Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingArrivalTimePicker) {
            ArrivalTimePickerView(
                selectedTime: $selectedArrivalTime,
                onSave: saveArrivalTime
            )
        }
        .sheet(isPresented: $showingPDF) {
            PDFViewerView(url: assignment.pdfUrl)
        }
    }
    
    private func saveArrivalTime() {
        Task {
            await assignmentsManager.updateArrivalTime(for: assignment.id, time: selectedArrivalTime)
        }
        showingArrivalTimePicker = false
    }
    
    private func markInProgress() {
        Task {
            await assignmentsManager.updateArrivalTime(for: assignment.id, time: Date())
        }
    }
    
    private func markComplete() {
        Task {
            await assignmentsManager.markAssignmentComplete(assignmentId: assignment.id)
        }
    }
}

struct ArrivalTimePickerView: View {
    @Binding var selectedTime: Date
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Set Arrival Time")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                DatePicker(
                    "Arrival Time",
                    selection: $selectedTime,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Button(action: {
                    onSave()
                    dismiss()
                }) {
                    Text("Save Arrival Time")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}



#Preview {
    AssignmentDetailView(assignment: Assignment(
        id: "1",
        title: "Morning Route - Downtown",
        description: "Deliver packages to downtown area. Start at warehouse and follow route map.",
        date: Date().addingTimeInterval(86400),
        status: .pending,
        pdfUrl: "https://example.com/assignment1.pdf",
        arrivalTime: nil
    ))
} 