import Foundation
import Apollo
import SchemaAPI

class NetworkManager {
    static let shared = NetworkManager()
    
    private var apollo: ApolloClient!
    
    private init() {
        setupApolloClient()
    }
    
    func setupApolloClient() {
        let cache = InMemoryNormalizedCache()
        let store = ApolloStore(cache: cache)
        
        let provider = DefaultInterceptorProvider(store: store)
        
        // Get URL from keychain or use default
        let urlString: String
        do {
            urlString = try KeychainManager.shared.getAPIURL()
        } catch {
            urlString = "http://localhost:4000/graphql"
        }
        
        let url = URL(string: urlString.replacingOccurrences(of: " ", with: ""))!
        let transport = RequestChainNetworkTransport(
            interceptorProvider: provider,
            endpointURL: url
        )
        
        apollo = ApolloClient(networkTransport: transport, store: store)
    }
    
    func getChats() async throws -> [ChatModel] {
        return try await withCheckedThrowingContinuation { continuation in
            apollo.fetch(query: GetChatsQuery()) { result in
                switch result {
                case .success(let graphQLResult):
                    if let chats = graphQLResult.data?.getChats {
                        // Convert Apollo types to our models
                        let chatModels = chats.map { chat -> ChatModel in
                            ChatModel(
                                id: chat.id,
                                name: chat.name,
                                createdAt: chat.createdAt,
                                messages: chat.messages.map { msg in
                                    MessageModel(
                                        id: msg.id,
                                        text: msg.text,
                                        role: msg.role.rawValue, // Convert enum to string
                                        createdAt: msg.createdAt,
                                        imageUrls: msg.imageUrls
                                    )
                                }
                            )
                        }
                        continuation.resume(returning: chatModels)
                    } else {
                        continuation.resume(throwing: NetworkError.noData)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func sendMessage(chatId: String, text: String) async throws -> MessageModel {
        return try await withCheckedThrowingContinuation { continuation in
            let mutation = SendMessageMutation(chatId: chatId, text: text)
            
            apollo.perform(mutation: mutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if let message = graphQLResult.data?.sendMessage {
                        // Convert Apollo type to our model
                        let messageModel = MessageModel(
                            id: message.id,
                            text: message.text,
                            role: message.role.rawValue, // Convert enum to string
                            createdAt: message.createdAt,
                            imageUrls: message.imageUrls
                        )
                        continuation.resume(returning: messageModel)
                    } else {
                        continuation.resume(throwing: NetworkError.noData)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func createChat(name: String) async throws -> ChatModel {
        return try await withCheckedThrowingContinuation { continuation in
            apollo.perform(mutation: CreateChatMutation(name: name)) { result in
                switch result {
                case .success(let graphQLResult):
                    if let chat = graphQLResult.data?.createChat {
                        // Convert Apollo type to our model
                        let chatModel = ChatModel(
                            id: chat.id,
                            name: chat.name,
                            createdAt: chat.createdAt,
                            messages: chat.messages.map { msg in
                                MessageModel(
                                    id: msg.id,
                                    text: msg.text,
                                    role: msg.role.rawValue,
                                    createdAt: msg.createdAt,
                                    imageUrls: msg.imageUrls
                                )
                            }
                        )
                        continuation.resume(returning: chatModel)
                    } else {
                        continuation.resume(throwing: NetworkError.noData)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Models
struct ChatModel: Identifiable, Codable {
    let id: String
    let name: String
    let createdAt: String
    var messages: [MessageModel]
}

struct MessageModel: Identifiable, Codable {
    let id: String
    let text: String?
    let role: String
    let createdAt: String
    let imageUrls: [String]
}

// MARK: - Errors
enum NetworkError: Error {
    case noData
}
