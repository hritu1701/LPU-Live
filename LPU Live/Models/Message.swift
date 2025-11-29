import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var senderId: String
    var senderName: String
    var content: String
    var timestamp: Date
    var readBy: [String] // List of User IDs who read the message
    var type: MessageType
    
    enum MessageType: String, Codable {
        case text
        case image
        case file
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId
        case senderName
        case content
        case timestamp
        case readBy
        case type
    }
}
