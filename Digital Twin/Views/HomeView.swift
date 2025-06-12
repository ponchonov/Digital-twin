import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var permissionManager = PermissionManager()
    @State private var showingError = false
    @State private var error: Error?
    @State private var newChat: ChatModel?
    @State private var isCreatingChat = false
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome and New Chat section
                    VStack(spacing: 20) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)
                        
                        Text("Welcome to Digital Twin")
                            .font(.title)
                        
                        // New Chat Button
                        Button {
                            startNewChat()
                        } label: {
                            HStack {
                                if isCreatingChat {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "plus.bubble.fill")
                                }
                                Text(isCreatingChat ? "Creating..." : "Start New Chat")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(isCreatingChat ? Color.gray : Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isCreatingChat)
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Latest chat section
                    if let firstChat = viewModel.latestChat {
                        VStack(alignment: .leading) {
                            Text("Continue your last conversation:")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            NavigationLink {
                                ChatConversationView(chat: firstChat)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(firstChat.name)
                                            .font(.subheadline)
                                            .bold()
                                        
                                        if let lastMessage = firstChat.messages.last {
                                            Text(lastMessage.text ?? "")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 30)
                    
                    // Permissions section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Connected Services")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("Tap to configure")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        
                        LazyVGrid(columns: gridColumns, spacing: 15) {
                            ForEach(PermissionType.allCases) { permission in
                                PermissionButton(
                                    type: permission,
                                    isGranted: permissionManager.permissionStates[permission] ?? false
                                ) {
                                    Task {
                                        await permissionManager.requestPermission(permission)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Home")
            .background(
                NavigationLink(
                    destination: Group {
                        if let chat = newChat {
                            ChatConversationView(chat: chat)
                        }
                    },
                    isActive: Binding(
                        get: { newChat != nil },
                        set: { if !$0 { newChat = nil } }
                    )
                ) {
                    EmptyView()
                }
            )
            .task {
                await viewModel.fetchChats()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    showingError = false
                }
            } message: {
                Text(error?.localizedDescription ?? "Unknown error occurred")
            }
        }
    }
    
    private func startNewChat() {
        isCreatingChat = true
        
        Task {
            do {
                let chat = try await viewModel.startNewChat()
                await MainActor.run {
                    newChat = chat
                    isCreatingChat = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    showingError = true
                    isCreatingChat = false
                }
            }
        }
    }
}

struct PermissionButton: View {
    let type: PermissionType
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: type.systemImage)
                        .font(.system(size: 24))
                        .foregroundStyle(isGranted ? .blue : .secondary)
                        .frame(width: 32, height: 32)
                    
                    if isGranted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.green)
                            .background(
                                Circle()
                                    .fill(.white)
                                    .frame(width: 15, height: 15)
                            )
                            .offset(x: 8, y: -8)
                    }
                }
                
                Text(type.title)
                    .font(.callout)
                    .foregroundStyle(isGranted ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 60)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published private(set) var latestChat: ChatModel?
    @Published private(set) var newChat: ChatModel?
    
    func fetchChats() async {
        do {
            let chats = try await NetworkManager.shared.getChats()
            latestChat = chats.first
        } catch {
            print("Error fetching chats: \(error)")
        }
    }
    
    func startNewChat() async throws -> ChatModel {
        let newChat = try await NetworkManager.shared.createChat(name: "New Conversation")
        await fetchChats() // Refresh the chats list
        return newChat
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
