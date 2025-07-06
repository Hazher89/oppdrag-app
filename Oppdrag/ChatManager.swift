//
//  ChatManager.swift
//  Oppdrag
//
//  Created by Hazher  on 05/07/2025.
//

import Foundation
import SwiftUI

class ChatManager: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    
    func loadConversations() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            // Demo data
            conversations = [
                Conversation(
                    id: "1",
                    title: "General Team Chat",
                    isGroup: true,
                    lastMessage: "Meeting tomorrow at 9 AM",
                    lastMessageTime: Date().addingTimeInterval(-3600),
                    unreadCount: 3,
                    participants: ["admin1", "driver1", "driver2"]
                ),
                Conversation(
                    id: "2",
                    title: "Dispatch Office",
                    isGroup: false,
                    lastMessage: "Your route has been updated",
                    lastMessageTime: Date().addingTimeInterval(-7200),
                    unreadCount: 1,
                    participants: ["admin1", "driver1"]
                ),
                Conversation(
                    id: "3",
                    title: "Emergency Support",
                    isGroup: false,
                    lastMessage: "Vehicle maintenance scheduled",
                    lastMessageTime: Date().addingTimeInterval(-86400),
                    unreadCount: 0,
                    participants: ["support", "driver1"]
                )
            ]
            isLoading = false
        }
    }
    
    func sendMessage(to conversationId: String, message: String) async {
        // Simulate sending message
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        await MainActor.run {
            if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                conversations[index].lastMessage = message
                conversations[index].lastMessageTime = Date()
                conversations[index].unreadCount = 0
            }
        }
    }
    
    func markAsRead(conversationId: String) async {
        await MainActor.run {
            if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                conversations[index].unreadCount = 0
            }
        }
    }
}

// MARK: - Chat Models
struct Conversation: Identifiable, Codable {
    let id: String
    let title: String
    let isGroup: Bool
    var lastMessage: String
    var lastMessageTime: Date
    var unreadCount: Int
    let participants: [String]
}

struct ChatMessage: Identifiable, Codable {
    let id: String
    let senderId: String
    let senderName: String
    let content: String
    let timestamp: Date
    let messageType: MessageType
    
    enum MessageType: String, Codable {
        case text = "text"
        case image = "image"
        case file = "file"
    }
}

struct NewChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedContacts: Set<String> = []
    @State private var chatTitle = ""
    
    let availableContacts = [
        "Dispatch Office",
        "Emergency Support",
        "Vehicle Maintenance",
        "General Team Chat"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("New Conversation")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Contacts")
                        .font(.headline)
                    
                    ForEach(availableContacts, id: \.self) { contact in
                        Button(action: {
                            if selectedContacts.contains(contact) {
                                selectedContacts.remove(contact)
                            } else {
                                selectedContacts.insert(contact)
                            }
                        }) {
                            HStack {
                                Image(systemName: selectedContacts.contains(contact) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedContacts.contains(contact) ? .blue : .gray)
                                
                                Text(contact)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if selectedContacts.count > 1 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Chat Name")
                            .font(.headline)
                        
                        TextField("Enter group name", text: $chatTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                Spacer()
                
                Button(action: {
                    // Create new conversation
                    dismiss()
                }) {
                    Text("Start Conversation")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedContacts.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(selectedContacts.isEmpty)
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
    NewChatView()
} 