import SwiftUI

@main
struct Digital_TwinApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.colorScheme) var deviceColorScheme
    
    private var effectiveColorScheme: ColorScheme? {
        switch appState.colorScheme {
        case .system:
            return deviceColorScheme
        default:
            return appState.colorScheme.colorScheme
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if KeychainManager.shared.hasAPIURL() {
                    ContentView()
                        .environmentObject(appState)
                } else {
                    NavigationStack {
                        QRScannerView()
                            .environmentObject(appState)
                    }
                }
            }
            .onChange(of: appState.refreshRequired) { _, needsRefresh in
                if needsRefresh {
                    // Reset the flag
                    appState.refreshRequired = false
                }
            }
            .preferredColorScheme(effectiveColorScheme)
        }
    }
}
