import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted = false
    @State private var showQRScanner = false
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Appearance") {
                    Picker("Color Scheme", selection: $appState.colorScheme) {
                        ForEach(ColorSchemePreference.allCases, id: \.self) { scheme in
                            HStack {
                                Image(systemName: scheme.iconName)
                                    .foregroundColor(.blue)
                                Text(scheme.displayName)
                            }
                            .tag(scheme)
                        }
                    }
                }
                
                Section("Configuration") {
                    Button(action: { showQRScanner = true }) {
                        HStack {
                            Text("Read API Configuration")
                            Spacer()
                            Image(systemName: "qrcode.viewfinder")
                        }
                    }
                    .foregroundColor(.blue)
                }
                
                Section("App Settings") {
                    Button(action: resetOnboarding) {
                        HStack {
                            Text("Show Onboarding")
                            Spacer()
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .foregroundColor(.blue)
                }
                
                Section {
                    Button(action: { showLogoutAlert = true }) {
                        HStack {
                            Text("Log Out")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showQRScanner) {
                QRScannerView()
            }
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Are you sure you want to log out? This will remove your API configuration.")
            }
        }
    }
    
    private func resetOnboarding() {
        isOnboardingCompleted = false
    }
    
    private func logout() {
        do {
            try KeychainManager.shared.deleteAPIURL()
            isOnboardingCompleted = false
        } catch {
            print("Error logging out: \(error)")
        }
    }
}

// MARK: - ColorSchemePreference Extensions
extension ColorSchemePreference {
    var displayName: String {
        switch self {
        case .light:
            return "Light Mode"
        case .dark:
            return "Dark Mode"
        case .system:
            return "System Default"
        }
    }
    
    var iconName: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "iphone"
        }
    }
}

