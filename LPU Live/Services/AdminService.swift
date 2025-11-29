import Foundation
import FirebaseFirestore
import Combine

class AdminService: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var totalUsers: Int = 0
    @Published var activeGroups: Int = 0
    @Published var messagesToday: Int = 0
    
    private var usersListener: ListenerRegistration?
    private var groupsListener: ListenerRegistration?
    
    func startListening() {
        listenToUsers()
        listenToGroups()
        fetchMessagesToday()
    }
    
    func stopListening() {
        usersListener?.remove()
        groupsListener?.remove()
    }
    
    private func listenToUsers() {
        usersListener = db.collection(FirebaseConfig.Collections.users)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching users count: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.totalUsers = documents.count
                }
            }
    }
    
    private func listenToGroups() {
        groupsListener = db.collection(FirebaseConfig.Collections.groups)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching groups count: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.activeGroups = documents.count
                }
            }
    }
    
    private func fetchMessagesToday() {
        // Get the start of today (midnight)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        Task {
            do {
                // Get all groups
                let groupsSnapshot = try await db.collection(FirebaseConfig.Collections.groups).getDocuments()
                
                var todayMessagesCount = 0
                
                // For each group, count messages from today
                for groupDoc in groupsSnapshot.documents {
                    let messagesSnapshot = try await db.collection(FirebaseConfig.Collections.groups)
                        .document(groupDoc.documentID)
                        .collection(FirebaseConfig.Collections.messages)
                        .whereField("timestamp", isGreaterThanOrEqualTo: startOfDay)
                        .getDocuments()
                    
                    todayMessagesCount += messagesSnapshot.documents.count
                }
                
                await MainActor.run {
                    self.messagesToday = todayMessagesCount
                }
            } catch {
                print("Error fetching messages today: \(error.localizedDescription)")
            }
        }
    }
    
    deinit {
        stopListening()
    }
}
