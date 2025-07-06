//
//  CoreDataService.swift
//  Oppdrag
//
//  Created by Hazher  on 05/07/2025.
//

import Foundation
import CoreData
import SwiftUI

class CoreDataService: ObservableObject {
    static let shared = CoreDataService()
    
    private let containerName = "DriveDispatch"
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: containerName)
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private init() {}
    
    // MARK: - Save Context
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Core Data save error: \(error)")
            }
        }
    }
    
    // MARK: - Assignment Operations
    func saveAssignment(_ assignment: Assignment) {
        let fetchRequest: NSFetchRequest<AssignmentEntity> = AssignmentEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", assignment.id)
        
        do {
            let existingAssignments = try context.fetch(fetchRequest)
            let assignmentEntity: AssignmentEntity
            
            if let existing = existingAssignments.first {
                assignmentEntity = existing
            } else {
                assignmentEntity = AssignmentEntity(context: context)
                assignmentEntity.id = assignment.id
            }
            
            assignmentEntity.title = assignment.title
            assignmentEntity.assignmentDescription = assignment.description
            assignmentEntity.date = assignment.date
            assignmentEntity.status = assignment.status.rawValue
            assignmentEntity.pdfUrl = assignment.pdfUrl
            assignmentEntity.arrivalTime = assignment.arrivalTime
            
            save()
        } catch {
            print("Error saving assignment: \(error)")
        }
    }
    
    func fetchAssignments() -> [Assignment] {
        let fetchRequest: NSFetchRequest<AssignmentEntity> = AssignmentEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { entity in
                guard let id = entity.id,
                      let title = entity.title,
                      let description = entity.assignmentDescription,
                      let statusString = entity.status,
                      let status = AssignmentStatus(rawValue: statusString),
                      let pdfUrl = entity.pdfUrl else {
                    return nil
                }
                
                return Assignment(
                    id: id,
                    title: title,
                    description: description,
                    date: entity.date ?? Date(),
                    status: status,
                    pdfUrl: pdfUrl,
                    arrivalTime: entity.arrivalTime
                )
            }
        } catch {
            print("Error fetching assignments: \(error)")
            return []
        }
    }
    
    func deleteAssignment(id: String) {
        let fetchRequest: NSFetchRequest<AssignmentEntity> = AssignmentEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let assignments = try context.fetch(fetchRequest)
            assignments.forEach { context.delete($0) }
            save()
        } catch {
            print("Error deleting assignment: \(error)")
        }
    }
    
    // MARK: - Chat Operations
    func saveConversation(_ conversation: Conversation) {
        let fetchRequest: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", conversation.id)
        
        do {
            let existingConversations = try context.fetch(fetchRequest)
            let conversationEntity: ConversationEntity
            
            if let existing = existingConversations.first {
                conversationEntity = existing
            } else {
                conversationEntity = ConversationEntity(context: context)
                conversationEntity.id = conversation.id
            }
            
            conversationEntity.title = conversation.title
            conversationEntity.isGroup = conversation.isGroup
            conversationEntity.lastMessage = conversation.lastMessage
            conversationEntity.lastMessageTime = conversation.lastMessageTime
            conversationEntity.unreadCount = Int32(conversation.unreadCount)
            conversationEntity.participants = conversation.participants
            
            save()
        } catch {
            print("Error saving conversation: \(error)")
        }
    }
    
    func fetchConversations() -> [Conversation] {
        let fetchRequest: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastMessageTime", ascending: false)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { entity in
                guard let id = entity.id,
                      let title = entity.title,
                      let lastMessage = entity.lastMessage,
                      let participants = entity.participants else {
                    return nil
                }
                
                return Conversation(
                    id: id,
                    title: title,
                    isGroup: entity.isGroup,
                    lastMessage: lastMessage,
                    lastMessageTime: entity.lastMessageTime ?? Date(),
                    unreadCount: Int(entity.unreadCount),
                    participants: participants
                )
            }
        } catch {
            print("Error fetching conversations: \(error)")
            return []
        }
    }
    
    func saveMessage(_ message: ChatMessage, conversationId: String) {
        let messageEntity = ChatMessageEntity(context: context)
        messageEntity.id = message.id
        messageEntity.senderId = message.senderId
        messageEntity.senderName = message.senderName
        messageEntity.content = message.content
        messageEntity.timestamp = message.timestamp
        messageEntity.messageType = message.messageType.rawValue
        messageEntity.conversationId = conversationId
        
        save()
    }
    
    func fetchMessages(conversationId: String) -> [ChatMessage] {
        let fetchRequest: NSFetchRequest<ChatMessageEntity> = ChatMessageEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "conversationId == %@", conversationId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { entity in
                guard let id = entity.id,
                      let senderId = entity.senderId,
                      let senderName = entity.senderName,
                      let content = entity.content,
                      let messageTypeString = entity.messageType,
                      let messageType = ChatMessage.MessageType(rawValue: messageTypeString) else {
                    return nil
                }
                
                return ChatMessage(
                    id: id,
                    senderId: senderId,
                    senderName: senderName,
                    content: content,
                    timestamp: entity.timestamp ?? Date(),
                    messageType: messageType
                )
            }
        } catch {
            print("Error fetching messages: \(error)")
            return []
        }
    }
    
    // MARK: - User Operations
    func saveUser(_ user: User) {
        let context = persistentContainer.viewContext
        
        // Check if user already exists
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", user.id)
        
        do {
            let existingUsers = try context.fetch(fetchRequest)
            let userEntity: UserEntity
            
            if let existingUser = existingUsers.first {
                userEntity = existingUser
            } else {
                userEntity = UserEntity(context: context)
                userEntity.id = user.id
            }
            
            // Update user data
            userEntity.email = user.email
            userEntity.name = user.name
            userEntity.role = user.role.rawValue
            userEntity.companyId = user.companyId
            userEntity.isEmailVerified = user.isEmailVerified ?? false
            
            try context.save()
            print("✅ User saved to Core Data: \(user.name)")
        } catch {
            print("❌ Error saving user to Core Data: \(error)")
        }
    }
    
    func fetchUser(id: String) -> User? {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let users = try context.fetch(fetchRequest)
            guard let entity = users.first else { return nil }
            
            return User(
                id: entity.id ?? "",
                email: entity.email ?? "",
                name: entity.name ?? "",
                role: UserRole(rawValue: entity.role ?? "driver") ?? .driver,
                companyId: entity.companyId ?? "",
                isEmailVerified: entity.isEmailVerified
            )
        } catch {
            print("❌ Error fetching user from Core Data: \(error)")
            return nil
        }
    }
    
    // MARK: - Clear All Data
    func clearAllData() {
        let entities = persistentContainer.managedObjectModel.entities
        
        entities.forEach { entity in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity.name!)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
            } catch {
                print("Error clearing \(entity.name ?? ""): \(error)")
            }
        }
        
        save()
    }
} 