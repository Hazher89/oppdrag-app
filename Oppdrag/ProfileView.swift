//
//  ProfileView.swift
//  Oppdrag
//
//  Created by Hazher  on 05/07/2025.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingSettings = false
    @State private var showingHelpSupport = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                            )
                        
                        VStack(spacing: 4) {
                            Text(authManager.currentUser?.name ?? "Driver")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(authManager.currentUser?.role.displayName ?? "Driver")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Quick Stats
                    HStack(spacing: 20) {
                        StatCard(
                            title: "Active",
                            value: "3",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Completed",
                            value: "12",
                            icon: "flag.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Pending",
                            value: "1",
                            icon: "clock.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                    
                    // Menu Items
                    VStack(spacing: 0) {
                        MenuRowView(
                            title: "Account Settings",
                            icon: "person.circle",
                            action: { showingSettings = true }
                        )
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        MenuRowView(
                            title: "Notifications",
                            icon: "bell",
                            action: { }
                        )
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        MenuRowView(
                            title: "Help & Support",
                            icon: "questionmark.circle",
                            action: { showingHelpSupport = true }
                        )
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        MenuRowView(
                            title: "About DriveDispatch",
                            icon: "info.circle",
                            action: { showingAbout = true }
                        )
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Logout Button
                    Button(action: {
                        authManager.signOut()
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            
                            Text("Sign Out")
                                .foregroundColor(.red)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingHelpSupport) {
                HelpSupportView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MenuRowView: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Notifications") {
                    Toggle("Push Notifications", isOn: $notificationsEnabled)
                    Toggle("Assignment Alerts", isOn: $notificationsEnabled)
                    Toggle("Chat Messages", isOn: $notificationsEnabled)
                }
                
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                }
                
                Section("Privacy") {
                    Button("Change Password") {
                        // Handle password change
                    }
                    .foregroundColor(.blue)
                    
                    Button("Delete Account") {
                        // Handle account deletion
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
}

struct HelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Help & Support")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Get help with using DriveDispatch")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // FAQ Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Frequently Asked Questions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            FAQItem(
                                question: "How do I start an assignment?",
                                answer: "Tap on an assignment in the Assignments tab, then tap 'Start Assignment' to begin."
                            )
                            
                            FAQItem(
                                question: "How do I set arrival time?",
                                answer: "In assignment details, tap 'Set Arrival Time' and choose your expected arrival time."
                            )
                            
                            FAQItem(
                                question: "How do I mark an assignment complete?",
                                answer: "When you're in progress, tap 'Mark Complete' in the assignment details."
                            )
                            
                            FAQItem(
                                question: "How do I view assignment PDFs?",
                                answer: "Tap 'View Assignment PDF' in the assignment details to open the document."
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Contact Support
                    VStack(spacing: 16) {
                        Text("Contact Support")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ContactItem(
                                title: "Emergency Support",
                                subtitle: "24/7 urgent assistance",
                                icon: "phone.fill",
                                color: .red
                            )
                            
                            ContactItem(
                                title: "Technical Support",
                                subtitle: "App and system issues",
                                icon: "wrench.fill",
                                color: .blue
                            )
                            
                            ContactItem(
                                title: "Dispatch Office",
                                subtitle: "Assignment and route questions",
                                icon: "message.fill",
                                color: .green
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("DriveDispatch")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // App Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About DriveDispatch")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Text("DriveDispatch is a comprehensive driver assignment management system designed to streamline delivery operations. Our app helps drivers efficiently manage their routes, communicate with dispatch, and track their progress.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Features")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            FeatureItem(
                                title: "Assignment Management",
                                description: "View and manage your delivery assignments",
                                icon: "doc.text.fill"
                            )
                            
                            FeatureItem(
                                title: "Real-time Chat",
                                description: "Communicate with dispatch and team members",
                                icon: "message.fill"
                            )
                            
                            FeatureItem(
                                title: "PDF Document Viewing",
                                description: "Access assignment details and route maps",
                                icon: "doc.fill"
                            )
                            
                            FeatureItem(
                                title: "Arrival Time Tracking",
                                description: "Set and track your arrival times",
                                icon: "clock.fill"
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Company Info
                    VStack(spacing: 12) {
                        Text("© 2025 DriveDispatch")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("All rights reserved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FAQItem: View {
    @State private var isExpanded = false
    let question: String
    let answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ContactItem: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FeatureItem: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
} 