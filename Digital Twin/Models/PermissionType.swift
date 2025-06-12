import Foundation
import HealthKit

enum PermissionType: Identifiable, CaseIterable {
    case health
    case email
    case whoop
    case telegram
    case slack
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .health: return "Health Data"
        case .email: return "Email Access"
        case .whoop: return "WHOOP Integration"
        case .telegram: return "Telegram Access"
        case .slack: return "Slack Access"
        }
    }
    
    var description: String {
        switch self {
        case .health:
            return "Access your health and fitness data to provide personalized insights"
        case .email:
            return "Connect your email to analyze communication patterns"
        case .whoop:
            return "Connect your WHOOP account to track recovery and strain"
        case .telegram:
            return "Access your Telegram chats for comprehensive analysis"
        case .slack:
            return "Access your Slack chats for comprehensive analysis"

        }
    }
    
    var systemImage: String {
        switch self {
        case .health: return "heart.fill"
        case .email: return "envelope.fill"
        case .whoop: return "figure.run"
        case .telegram: return "message.fill"
        case .slack: return "message.fill"

        }
    }
}
