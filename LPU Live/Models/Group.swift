import Foundation
import FirebaseFirestore

struct Group: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String // e.g., "K22GX - INT315"
    var description: String?
    var createdBy: String // Admin ID
    var members: [String] // List of User IDs
    var teachers: [String] // List of Teacher IDs who can post
    var createdAt: Date
    var lastMessage: String?
    var lastMessageTime: Date?
    var isPersonal: Bool = false
    var logoUrl: String? = "group_default_logo"
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case createdBy
        case members
        case teachers
        case createdAt
        case lastMessage
        case lastMessageTime
        case isPersonal
        case logoUrl
    }
}
