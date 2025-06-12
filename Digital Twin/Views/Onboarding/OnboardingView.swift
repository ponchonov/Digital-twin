import SwiftUI
import HealthKit

struct OnboardingView: View {
    @Binding var isOnboardingCompleted: Bool
    @StateObject private var permissionManager = PermissionManager()
    @State private var currentStep = 0
    
    var body: some View {
        TabView(selection: $currentStep) {
            // Welcome Page
            WelcomeStepView(currentStep: $currentStep)
                .tag(0)
            
            // Permission Pages
            ForEach(Array(PermissionType.allCases.enumerated()), id: \.element) { index, permission in
                PermissionStepView(
                    permission: permission,
                    isGranted: permissionManager.permissionStates[permission] ?? false,
                    currentStep: $currentStep,
                    requestPermission: {
                        Task {
                            await permissionManager.requestPermission(permission)
                        }
                    }
                )
                .tag(index + 1)
            }
            
            // Final Step
            FinalStepView(isOnboardingCompleted: $isOnboardingCompleted)
                .tag(PermissionType.allCases.count + 1)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .never))
    }
}

// Welcome Step
private struct WelcomeStepView: View {
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Welcome to Digital Twin")
                .font(.title)
                .bold()
            
            Text("Your AI-powered digital companion")
                .font(.title2)
            
            Text("Let's set up your digital twin by connecting your data sources.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button("Get Started") {
                withAnimation {
                    currentStep += 1
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
        .padding()
    }
}

// Permission Step
private struct PermissionStepView: View {
    let permission: PermissionType
    let isGranted: Bool
    @Binding var currentStep: Int
    let requestPermission: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: permission.systemImage)
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Connect \(permission.title)")
                .font(.title)
                .bold()
            
            Text(permission.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            if isGranted {
                Label("Access Granted", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            HStack(spacing: 20) {
                Button(isGranted ? "Continue" : "Grant Access") {
                    if isGranted {
                        withAnimation {
                            currentStep += 1
                        }
                    } else {
                        requestPermission()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                if !isGranted {
                    Button("Skip") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.bottom)
        }
        .padding()
    }
}

// Final Step
private struct FinalStepView: View {
    @Binding var isOnboardingCompleted: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("You're All Set!")
                .font(.title)
                .bold()
            
            Text("Your digital twin is ready to assist you")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button("Start Using Digital Twin") {
                withAnimation {
                    isOnboardingCompleted = true
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
        .padding()
    }
}

#Preview {
    OnboardingView(isOnboardingCompleted: .constant(false))
}
