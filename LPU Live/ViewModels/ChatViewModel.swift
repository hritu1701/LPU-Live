import Foundation
import FirebaseFirestore
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var newMessageText: String = ""
    @Published var isLoading: Bool = false
    
    private let chatService = ChatService()
    private var listener: ListenerRegistration?
    let group: Group
    let currentUser: User?
    
    init(group: Group, currentUser: User?) {
        self.group = group
        self.currentUser = currentUser
        fetchMessages()
    }
    
    deinit {
        listener?.remove()
    }
    
    func fetchMessages() {
        guard let groupId = group.id else { return }
        
        isLoading = true
        
        listener = chatService.fetchMessages(groupId: groupId) { [weak self] messages in
            self?.messages = messages
            self?.isLoading = false
        }
    }
    
    func sendMessage() async {
        guard !newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let currentUser = currentUser,
              let groupId = group.id else { return }
        
        let content = newMessageText
        
        // Optimistic UI update (optional, but good for UX)
        // For now, we rely on the listener
        
        await MainActor.run {
            newMessageText = ""
        }
        
        do {
            // Use "Admin" as display name for admin users
            let displayName = currentUser.role == .admin ? "Admin" : currentUser.name
            
            try await chatService.sendMessage(
                groupId: groupId,
                content: content,
                senderId: currentUser.userId,
                senderName: displayName
            )
        } catch {
            print("Error sending message: \(error.localizedDescription)")
        }
    }
    
    var canSendMessage: Bool {
        guard let user = currentUser else { return false }
        
        // Admins and Teachers can always send messages
        if user.role == .admin || user.role == .teacher {
            return true
        }
        
        // Students can send messages in personal groups/DMs only
        return group.isPersonal
    }
    
    func clearChat() async {
        guard let groupId = group.id else { return }
        
        do {
            try await chatService.clearChat(groupId: groupId)
        } catch {
            print("Error clearing chat: \(error.localizedDescription)")
        }
    }
}
