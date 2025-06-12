// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class SendMessageMutation: GraphQLMutation {
  public static let operationName: String = "SendMessage"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation SendMessage($chatId: ID!, $text: String!) { sendMessage(chatId: $chatId, text: $text) { __typename id text role createdAt imageUrls toolCalls { __typename id name isCompleted result { __typename content imageUrls } } } }"#
    ))

  public var chatId: ID
  public var text: String

  public init(
    chatId: ID,
    text: String
  ) {
    self.chatId = chatId
    self.text = text
  }

  public var __variables: Variables? { [
    "chatId": chatId,
    "text": text
  ] }

  public struct Data: SchemaAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { SchemaAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("sendMessage", SendMessage.self, arguments: [
        "chatId": .variable("chatId"),
        "text": .variable("text")
      ]),
    ] }

    public var sendMessage: SendMessage { __data["sendMessage"] }

    /// SendMessage
    ///
    /// Parent Type: `Message`
    public struct SendMessage: SchemaAPI.SelectionSet {
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
        .field("toolCalls", [ToolCall].self),
      ] }

      public var id: SchemaAPI.ID { __data["id"] }
      public var text: String? { __data["text"] }
      public var role: GraphQLEnum<SchemaAPI.Role> { __data["role"] }
      public var createdAt: SchemaAPI.DateTime { __data["createdAt"] }
      public var imageUrls: [String] { __data["imageUrls"] }
      public var toolCalls: [ToolCall] { __data["toolCalls"] }

      /// SendMessage.ToolCall
      ///
      /// Parent Type: `ToolCall`
      public struct ToolCall: SchemaAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { SchemaAPI.Objects.ToolCall }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("name", String.self),
          .field("isCompleted", Bool.self),
          .field("result", Result?.self),
        ] }

        public var id: String { __data["id"] }
        public var name: String { __data["name"] }
        public var isCompleted: Bool { __data["isCompleted"] }
        public var result: Result? { __data["result"] }

        /// SendMessage.ToolCall.Result
        ///
        /// Parent Type: `ToolCallResult`
        public struct Result: SchemaAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { SchemaAPI.Objects.ToolCallResult }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("content", String?.self),
            .field("imageUrls", [String].self),
          ] }

          public var content: String? { __data["content"] }
          public var imageUrls: [String] { __data["imageUrls"] }
        }
      }
    }
  }
}
