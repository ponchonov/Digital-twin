import SwiftUI
import Kingfisher
import UniformTypeIdentifiers

struct ChatsListView: View {
    @StateObject private var viewModel = ChatsViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.chats.isEmpty && viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.chats) { chat in
                        NavigationLink(destination: ChatConversationView(chat: chat)) {
                            ChatPreviewRow(chat: chat)
                        }
                    }
                }
            }
            .navigationTitle("Chats")
            .task {
                if viewModel.chats.isEmpty {
                    await viewModel.fetchChats()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("Retry") {
                    Task {
                        await viewModel.fetchChats()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? "Unknown error")
            }
            .refreshable {
                await viewModel.fetchChats()
            }
        }
    }
}

@MainActor
class ChatsViewModel: ObservableObject {
    @Published private(set) var chats: [ChatModel] = []
    @Published private(set) var isLoading = false
    @Published var error: Error?
    
    func fetchChats() async {
        // Don't show loading if we have existing chats
        let shouldShowLoading = chats.isEmpty
        if shouldShowLoading {
            isLoading = true
        }
        
        do {
            let newChats = try await NetworkManager.shared.getChats()
            
            // Animate changes if we had existing chats
            if !chats.isEmpty {
                withAnimation {
                    self.chats = newChats
                }
            } else {
                self.chats = newChats
            }
            error = nil
        } catch {
            self.error = error
        }
        
        if shouldShowLoading {
            isLoading = false
        }
    }
}

struct ChatPreviewRow: View {
    let chat: ChatModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(chat.name)
                .font(.headline)
            
            Text(formatDate(chat.createdAt))
                .font(.caption)
                .foregroundColor(.gray)
            
            if let lastMessage = chat.messages.last?.text {
                Text(lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        if let date = ISO8601DateFormatter().date(from: dateString) {
            return formatter.string(from: date)
        }
        return dateString
    }
}

struct ChatConversationView: View {
    let chat: ChatModel
    @State private var messageText = ""
    @State private var messages: [MessageModel]
    @State private var error: Error?
    @State private var scrollProxy: ScrollViewProxy?
    @State private var isTyping = false
    
    init(chat: ChatModel) {
        self.chat = chat
        _messages = State(initialValue: chat.messages)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(messages) { message in
                            ChatMessageView(message: message)
                                .id(message.id)
                        }
                        
                        if isTyping {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.blue)
                                
                                TypingIndicatorView()
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            .id("typingIndicator")
                        }
                    }
                    .padding(.vertical)
                }
                .onAppear {
                    scrollProxy = proxy
                    scrollToBottom()
                }
                .onChange(of: isTyping) { _, isTyping in
                    if isTyping {
                        scrollToTypingIndicator()
                    }
                }
            }
            
            Divider()
            
            ChatInputField(text: $messageText, onSend: sendMessage)
        }
        .navigationTitle(chat.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") {
                error = nil
            }
        } message: {
            Text(error?.localizedDescription ?? "Unknown error")
        }
    }
    
    private func scrollToBottom() {
        guard let lastMessage = messages.last else { return }
        withAnimation {
            scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
    
    private func scrollToTypingIndicator() {
        withAnimation {
            scrollProxy?.scrollTo("typingIndicator", anchor: .bottom)
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        // Create temporary message
        let tempMessage = MessageModel(
            id: UUID().uuidString,
            text: messageText,
            role: "USER",
            createdAt: ISO8601DateFormatter().string(from: Date()),
            imageUrls: []
        )
        
        // Add message to UI immediately
        messages.append(tempMessage)
        
        // Clear input
        messageText = ""
        
        // Scroll to bottom
        scrollToBottom()
        
        // Send to server
        Task {
            do {
                // Show typing indicator
                await MainActor.run {
                    isTyping = true
                }
                
                let result = try await NetworkManager.shared.sendMessage(chatId: chat.id, text: tempMessage.text ?? "")
                
                // Hide typing indicator and append response
                await MainActor.run {
                    isTyping = false
                    messages.append(result)
                    scrollToBottom()
                }
                
            } catch {
                await MainActor.run {
                    self.error = error
                    isTyping = false
                    // Remove temporary message if failed
                    messages.removeAll { $0.id == tempMessage.id }
                }
            }
        }
    }
}

struct CachedAsyncImage: View {
    let url: String
    @State private var image: UIImage?
    @State private var loadingTask: Task<UIImage, Error>?
    @State private var showingPreview = false  // Add state for showing preview
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .onTapGesture {  // Add tap gesture
                        showingPreview = true
                    }
            } else {
                ProgressView()
                    .task {
                        loadingTask = ImageCache.shared.loadImage(url: url)
                        do {
                            if let task = loadingTask {
                                image = try await task.value
                            }
                        } catch {
                            print("Error loading image: \(error)")
                        }
                    }
            }
        }
        .sheet(isPresented: $showingPreview) {  // Bind to showingPreview state
            ImagePreviewView(imageUrl: url)
        }
    }
}

import UniformTypeIdentifiers

extension UIImage: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .image) { image in
            if let data = image.pngData() {
                return data
            } else {
                return Data()
            }
        } importing: { data in
            if let image = UIImage(data: data) {
                return image
            } else {
                return UIImage()
            }
        }
    }
}

struct ImagePreviewView: View {
    let imageUrl: String
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground) // Add background color
                    .ignoresSafeArea()
                
                Group {
                    if let image = image {
                        GeometryReader { geo in
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                    } else {
                        ProgressView()
                            .task {
                                await loadImage()
                            }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Text("Close")
                        }
                        .foregroundStyle(.blue) // Use system blue color
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let image = image {
                        ShareLink(
                            item: image,
                            preview: SharePreview("Image", image: Image(uiImage: image))
                        )
                    }
                }
            }
        }
        .presentationBackground(.clear) // Make sheet background clear
        .presentationDragIndicator(.visible) // Add drag indicator for better UX
    }
    
    private func loadImage() async {
        // Check cache first
        if let cached = ImageCache.shared.get(forKey: imageUrl) {
            self.image = cached
            return
        }
        
        // Load from network if not cached
        guard let url = URL(string: imageUrl) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                ImageCache.shared.set(image, forKey: url.absoluteString)
                self.image = image
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }
}

class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    private var loadingTasks: [String: Task<UIImage, Error>] = [:]
    private let taskQueue = DispatchQueue(label: "com.app.ImageCache.taskQueue")
    
    func get(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func loadImage(url urlString: String) -> Task<UIImage, Error> {
        // Synchronize access to loadingTasks
        taskQueue.sync {
            // Return existing task if already loading
            if let existingTask = loadingTasks[urlString] {
                return existingTask
            }
            
            let task = Task {
                defer {
                    taskQueue.async {
                        self.loadingTasks[urlString] = nil
                    }
                }
                
                // Check cache first
                if let cachedImage = get(forKey: urlString) {
                    return cachedImage
                }
                
                guard let url = URL(string: urlString) else {
                    throw URLError(.badURL)
                }
                
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else {
                    throw URLError(.cannotDecodeRawData)
                }
                
                // Store in cache
                set(image, forKey: urlString)
                return image
            }
            
            loadingTasks[urlString] = task
            return task
        }
    }
}

struct ChatMessageView: View {
    let message: MessageModel
    @State private var parseError: String?
    
    private var isUser: Bool {
        message.role == "USER"
    }
    
    private var attributedText: AttributedString {
        guard let text = message.text else {
            return AttributedString("No message text")
        }
        
        if !isUser {
            do {
                let attributed = try AttributedString(markdown: text)
                
                // Apply additional styling
                var mutableAttributed = attributed
                mutableAttributed.foregroundColor = isUser ? .white : .primary
                return mutableAttributed
            } catch {
                // Don't modify state here, just return plain text
                print("Markdown parsing error: \(error)")
                var plainText = AttributedString(text)
                plainText.foregroundColor = isUser ? .white : .primary
                return plainText
            }
        }
        
        // Default to plain text for user messages
        var plainText = AttributedString(text)
        plainText.foregroundColor = isUser ? .white : .primary
        return plainText
    }
    
    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading) {
            HStack {
                if !isUser {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                    VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                        Text(attributedText)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if !message.imageUrls.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(message.imageUrls, id: \.self) { url in
                                        CachedAsyncImage(url: url)
                                            .frame(width: 200, height: 150)
                                            .cornerRadius(8)
                                            .clipped()
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(isUser ? Color.blue : Color(.systemGray5))
                    .cornerRadius(12)
                    
                    Text(formatDate(message.createdAt))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: isUser ? .trailing : .leading)
                
                if isUser {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        if let date = ISO8601DateFormatter().date(from: dateString) {
            return formatter.string(from: date)
        }
        return dateString
    }
}

struct ChatInputField: View {
    @Binding var text: String
    let onSend: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isFocused)
                .submitLabel(.send)
                .onSubmit {
                    if !text.isEmpty {
                        onSend()
                    }
                }
            
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(text.isEmpty ? Color.gray : Color.blue)
                    .clipShape(Circle())
            }
            .disabled(text.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ChatsListView()
}
