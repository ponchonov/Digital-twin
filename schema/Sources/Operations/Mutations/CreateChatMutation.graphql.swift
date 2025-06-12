// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class CreateChatMutation: GraphQLMutation {
  public static let operationName: String = "CreateChat"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation CreateChat($name: String!) { createChat(name: $name) { __typename id name createdAt messages { __typename id text role createdAt imageUrls } } }"#
    ))

  public var name: String

  public init(name: String) {
    self.name = name
  }

  public var __variables: Variables? { ["name": name] }

  public struct Data: SchemaAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { SchemaAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("createChat", CreateChat.self, arguments: ["name": .variable("name")]),
    ] }

    public var createChat: CreateChat { __data["createChat"] }

    /// CreateChat
    ///
    /// Parent Type: `Chat`
    public struct CreateChat: SchemaAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { SchemaAPI.Objects.Chat }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", SchemaAPI.ID.self),
        .field("name", String.self),
        .field("createdAt", SchemaAPI.DateTime.self),
        .field("messages", [Message].self),
      ] }

      public var id: SchemaAPI.ID { __data["id"] }
      public var name: String { __data["name"] }
      public var createdAt: SchemaAPI.DateTime { __data["createdAt"] }
      public var messages: [Message] { __data["messages"] }

      /// CreateChat.Message
      ///
      /// Parent Type: `Message`
      public struct Message: SchemaAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { SchemaAPI.Objects.Message }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", SchemaAPI.ID.self),
          .field("text", String?.self),
          .field("role", GraphQLEnum<SchemaAPI.Role>.self),
          .field("createdAt", SchemaAPI.DateTime.self),
          .field("imageUrls", [String].self),
        ] }

        public var id: SchemaAPI.ID { __data["id"] }
        public var text: String? { __data["text"] }
        public var role: GraphQLEnum<SchemaAPI.Role> { __data["role"] }
        public var createdAt: SchemaAPI.DateTime { __data["createdAt"] }
        public var imageUrls: [String] { __data["imageUrls"] }
      }
    }
  }
}
