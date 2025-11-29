import Foundation
import FirebaseFirestore
import Combine

class UserService: ObservableObject {
    private let db = Firestore.firestore()
    
    func searchUsers(query: String) async throws -> [User] {
        // Simple search by name or ID (prefix match)
        // Note: Firestore doesn't support native full-text search. 
        // We'll do a simple prefix search on 'name' for now.
        
        let snapshot = try await db.collection(FirebaseConfig.Collections.users)
            .whereField("name", isGreaterThanOrEqualTo: query)
            .whereField("name", isLessThan: query + "z")
            .limit(to: 20)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: User.self) }
    }
    
    func fetchAllUsers() async throws -> [User] {
        let snapshot = try await db.collection(FirebaseConfig.Collections.users)
            .limit(to: 50)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: User.self) }
    }
    
    func updateUserRole(userId: String, role: UserRole) async throws {
        try await db.collection(FirebaseConfig.Collections.users).document(userId).updateData([
            "role": role.rawValue
        ])
    }
    
    func updateUserAvatar(userId: String, avatar: String) async throws {
        try await db.collection(FirebaseConfig.Collections.users).document(userId).updateData([
            "profileImageUrl": avatar
        ])
    }
    
    func fetchUsers(byIds userIds: [String]) async throws -> [User] {
        guard !userIds.isEmpty else { return [] }
        
        // Firestore 'in' query supports up to 10 items at a time
        let batchSize = 10
        var allUsers: [User] = []
        
        for i in stride(from: 0, to: userIds.count, by: batchSize) {
            let end = min(i + batchSize, userIds.count)
            let batch = Array(userIds[i..<end])
            
            let snapshot = try await db.collection(FirebaseConfig.Collections.users)
                .whereField("userId", in: batch)
                .getDocuments()
            
            let users = snapshot.documents.compactMap { try? $0.data(as: User.self) }
            allUsers.append(contentsOf: users)
        }
        
        return allUsers
    }
    
    func validateUsers(userIds: [String]) async -> (valid: [String], invalid: [String]) {
        var validUsers: [String] = []
        var invalidUsers: [String] = []
        
        print("🔍 Validating users: \(userIds)")
        
        for userId in userIds {
            do {
                let snapshot = try await db.collection(FirebaseConfig.Collections.users)
                    .whereField("userId", isEqualTo: userId)
                    .limit(to: 1)
                    .getDocuments()
                
                if !snapshot.documents.isEmpty {
                    print("✅ User found: \(userId)")
                    validUsers.append(userId)
                } else {
                    print("❌ User NOT found: \(userId)")
                    invalidUsers.append(userId)
                }
            } catch {
                print("❌ Error validating user \(userId): \(error.localizedDescription)")
                invalidUsers.append(userId)
            }
        }
        
        print("📊 Validation result - Valid: \(validUsers), Invalid: \(invalidUsers)")
        return (validUsers, invalidUsers)
    }
}
