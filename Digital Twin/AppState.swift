import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var colorScheme: ColorSchemePreference {
        didSet {
            UserDefaults.standard.setValue(colorScheme.rawValue, forKey: "app_color_scheme")
        }
    }
    @Published var chats: [ChatModel] = []
    @Published var error: Error?
    @Published var refreshRequired = false
    
    init() {
        // Load saved color scheme or default to system
        if let savedScheme = UserDefaults.standard.string(forKey: "app_color_scheme"),
           let preference = ColorSchemePreference(rawValue: savedScheme) {
            self.colorScheme = preference
        } else {
            self.colorScheme = .system
        }
    }
    
    func refresh() {
        Task {
            do {
                chats = try await NetworkManager.shared.getChats()
            } catch {
                self.error = error
            }
        }
    }
}

enum ColorSchemePreference: String, CaseIterable {
    case light, dark, system
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil // This will be handled by effectiveColorScheme in the app
        }
    }
}
