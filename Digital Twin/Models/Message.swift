import Foundation
import SwiftUI

public enum MessageContent: Codable, Equatable {
    case text(String)
    case image(URL)
    
    // Custom coding keys for encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case type, value
    }
    
    // Custom encoding
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let string):
            try container.encode("text", forKey: .type)
            try container.encode(string, forKey: .value)
        case .image(let url):
            try container.encode("image", forKey: .type)
            try container.encode(url, forKey: .value)
        }
    }
    
    // Custom decoding
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "text":
            let value = try container.decode(String.self, forKey: .value)
            self = .text(value)
        case "image":
            let value = try container.decode(URL.self, forKey: .value)
            self = .image(value)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Invalid message type"
            )
        }
    }
}

struct Message: Identifiable, Codable {
    let id: UUID
    let content: MessageContent
    let isUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), content: MessageContent, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}
