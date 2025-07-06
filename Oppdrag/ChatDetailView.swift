//
//  ChatDetailView.swift
//  Oppdrag
//
//  Created by Hazher  on 05/07/2025.
//

import SwiftUI

struct ChatDetailView: View {
    let conversation: Conversation
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var chatManager = ChatManager()
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubbleView(
                                message: message,
                                isFromCurrentUser: message.senderId == authManager.currentUser?.id
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .onChange(of: messages.count) { _, _ in
                    if let lastMessage = messages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message Input
            MessageInputView(
                text: $messageText,
                onSend: sendMessage
            )
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMessages()
        }
    }
    
    private func loadMessages() {
        // Demo messages
        messages = [
            ChatMessage(
                id: "1",
                senderId: "admin1",
                senderName: "Dispatch Office",
                content: "Good morning! Your route for today has been assigned.",
                timestamp: Date().addingTimeInterval(-3600),
                messageType: .text
            ),
            ChatMessage(
                id: "2",
                senderId: authManager.currentUser?.id ?? "driver1",
                senderName: authManager.currentUser?.name ?? "Driver",
                content: "Thank you! I'll review the assignment now.",
                timestamp: Date().addingTimeInterval(-3500),
                messageType: .text
            ),
            ChatMessage(
                id: "3",
                senderId: "admin1",
                senderName: "Dispatch Office",
                content: "Please confirm your arrival time when you start the route.",
                timestamp: Date().addingTimeInterval(-3400),
                messageType: .text
            ),
            ChatMessage(
                id: "4",
                senderId: authManager.currentUser?.id ?? "driver1",
                senderName: authManager.currentUser?.name ?? "Driver",
                content: "Will do. Starting the route now.",
                timestamp: Date().addingTimeInterval(-3300),
                messageType: .text
            )
        ]
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newMessage = ChatMessage(
            id: UUID().uuidString,
            senderId: authManager.currentUser?.id ?? "",
            senderName: authManager.currentUser?.name ?? "Driver",
            content: messageText,
            timestamp: Date(),
            messageType: .text
        )
        
        messages.append(newMessage)
        
        Task {
            await chatManager.sendMessage(to: conversation.id, message: messageText)
        }
        
        messageText = ""
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isFromCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(18)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isFromCurrentUser {
                Spacer(minLength: 50)
            }
        }
    }
}

struct MessageInputView: View {
    @Binding var text: String
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $text, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...4)
            
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(16)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.systemGray4)),
            alignment: .top
        )
    }
}

#Preview {
    NavigationView {
        ChatDetailView(conversation: Conversation(
            id: "1",
            title: "Dispatch Office",
            isGroup: false,
            lastMessage: "Your route has been updated",
            lastMessageTime: Date(),
            unreadCount: 0,
            participants: ["admin1", "driver1"]
        ))
        .environmentObject(AuthenticationManager())
    }
} 