// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class GetChatsQuery: GraphQLQuery {
  public static let operationName: String = "GetChats"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query GetChats { getChats(first: 11, offset: 5) { __typename id name createdAt messages { __typename text imageUrls id createdAt role } } }"#
    ))

  public init() {}

  public struct Data: SchemaAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { SchemaAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("getChats", [GetChat].self, arguments: [
        "first": 11,
        "offset": 5
      ]),
    ] }

    public var getChats: [GetChat] { __data["getChats"] }

    /// GetChat
    ///
    /// Parent Type: `Chat`
    public struct GetChat: SchemaAPI.SelectionSet {
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

      /// GetChat.Message
      ///
      /// Parent Type: `Message`
      public struct Message: SchemaAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { SchemaAPI.Objects.Message }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("text", String?.self),
          .field("imageUrls", [String].self),
          .field("id", SchemaAPI.ID.self),
          .field("createdAt", SchemaAPI.DateTime.self),
          .field("role", GraphQLEnum<SchemaAPI.Role>.self),
        ] }

        public var text: String? { __data["text"] }
        public var imageUrls: [String] { __data["imageUrls"] }
        public var id: SchemaAPI.ID { __data["id"] }
        public var createdAt: SchemaAPI.DateTime { __data["createdAt"] }
        public var role: GraphQLEnum<SchemaAPI.Role> { __data["role"] }
      }
    }
  }
}
