import Foundation
import FirebaseFirestore
import Combine

class ChatService: ObservableObject {
    private let db = Firestore.firestore()
    
    func fetchMessages(groupId: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        return db.collection(FirebaseConfig.Collections.groups)
            .document(groupId)
            .collection(FirebaseConfig.Collections.messages)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching messages: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let messages = documents.compactMap { document -> Message? in
                    try? document.data(as: Message.self)
                }
                
                completion(messages)
            }
    }
    
    func sendMessage(groupId: String, content: String, senderId: String, senderName: String) async throws {
        let message = Message(
            senderId: senderId,
            senderName: senderName,
            content: content,
            timestamp: Date(),
            readBy: [senderId],
            type: .text
        )
        
        let groupRef = db.collection(FirebaseConfig.Collections.groups).document(groupId)
        let messagesRef = groupRef.collection(FirebaseConfig.Collections.messages)
        
        // Add message
        try messagesRef.addDocument(from: message)
        
        // Update group last message
        try await groupRef.updateData([
            "lastMessage": content,
            "lastMessageTime": Date()
        ])
    }
    
    func fetchGroups(for userId: String? = nil, completion: @escaping ([Group]) -> Void) -> ListenerRegistration {
        var query: Query = db.collection(FirebaseConfig.Collections.groups)
        
        // If a userId is provided, filter groups where they are a member
        if let userId = userId {
            query = query.whereField("members", arrayContains: userId)
        }
        
        return query
            .order(by: "lastMessageTime", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching groups: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let groups = documents.compactMap { try? $0.data(as: Group.self) }
                completion(groups)
            }
    }
    
    func clearChat(groupId: String) async throws {
        let messagesRef = db.collection(FirebaseConfig.Collections.groups)
            .document(groupId)
            .collection(FirebaseConfig.Collections.messages)
        
        let snapshot = try await messagesRef.getDocuments()
        
        // Delete all messages in a batch
        let batch = db.batch()
        snapshot.documents.forEach { document in
            batch.deleteDocument(document.reference)
        }
        
        try await batch.commit()
        print("✅ Chat cleared successfully")
        
        // Update group last message
        try await db.collection(FirebaseConfig.Collections.groups)
            .document(groupId)
            .updateData([
                "lastMessage": "Chat cleared by admin",
                "lastMessageTime": Date()
            ])
        
        print("✅ Chat cleared successfully for group: \(groupId)")
    }
    
    func deleteGroup(groupId: String) async throws {
        // First, delete all messages in the group
        let messagesRef = db.collection(FirebaseConfig.Collections.groups)
            .document(groupId)
            .collection(FirebaseConfig.Collections.messages)
        
        let snapshot = try await messagesRef.getDocuments()
        
        // Delete all messages in a batch
        let batch = db.batch()
        snapshot.documents.forEach { document in
            batch.deleteDocument(document.reference)
        }
        
        try await batch.commit()
        print("✅ All messages deleted")
        
        // Then delete the group document itself
        try await db.collection(FirebaseConfig.Collections.groups)
            .document(groupId)
            .delete()
        
        print("✅ Group document deleted")
    }
    
    func createOrGetDirectMessage(currentUserId: String, otherUserId: String, otherUserName: String) async throws -> Group {
        // Check if a DM already exists between these two users
        let snapshot = try await db.collection(FirebaseConfig.Collections.groups)
            .whereField("isPersonal", isEqualTo: true)
            .whereField("members", arrayContains: currentUserId)
            .getDocuments()
        
        // Find existing DM
        for document in snapshot.documents {
            if let group = try? document.data(as: Group.self),
               group.members.count == 2,
               group.members.contains(otherUserId) {
                print("✅ Found existing DM: \(group.id ?? "unknown")")
                return group
            }
        }
        
        // Create new DM if none exists
        let newDM = Group(
            name: otherUserName,  // DM name is the other user's name
            description: nil,
            createdBy: currentUserId,
            members: [currentUserId, otherUserId],
            teachers: [],
            createdAt: Date(),
            lastMessage: nil,
            lastMessageTime: Date(),
            isPersonal: true,
            logoUrl: "group_default_logo"
        )
        
        let docRef = try db.collection(FirebaseConfig.Collections.groups).addDocument(from: newDM)
        
        // Fetch the newly created group to get its ID
        let newSnapshot = try await docRef.getDocument()
        guard let createdGroup = try? newSnapshot.data(as: Group.self) else {
            throw NSError(domain: "ChatService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create DM"])
        }
        
        print("✅ Created new DM: \(createdGroup.id ?? "unknown")")
        return createdGroup
    }
}
