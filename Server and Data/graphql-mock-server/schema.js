const { gql } = require('graphql-tag');

module.exports = gql`
  scalar DateTime
  scalar JSON

  type UserProfile {
    name: String
    bio: String
  }

  input UpdateProfileInput {
    name: String
    bio: String
  }

  type ToolCallResult {
    content: String
    imageUrls: [String!]!
  }

  type ToolCall {
    id: String!
    name: String!
    isCompleted: Boolean!
    messageId: String!
    result: ToolCallResult
  }

  type Chat {
    id: ID!
    name: String!
    messages: [Message!]!
    createdAt: DateTime!
  }

  type Message {
    id: ID!
    text: String
    imageUrls: [String!]!
    role: Role!
    toolCalls: [ToolCall!]!
    toolResults: [String!]!
    createdAt: DateTime!
  }

  enum Role {
    USER
    ASSISTANT
  }

  type Query {
    profile: UserProfile!
    getChats(first: Int! = 10, offset: Int! = 0): [Chat!]!
    getChat(id: ID!): Chat!
  }

  type Mutation {
    updateProfile(input: UpdateProfileInput!): Boolean!
    sendMessage(chatId: ID!, text: String!): Message!
    createChat(name: String!): Chat!
    deleteChat(chatId: ID!): Chat!
  }

  type Subscription {
    messageAdded(chatId: ID!): Message!
    toolCallUpdated(chatId: ID!): ToolCall!
  }

  type Tool {
    name: String!
    description: String!
  }
`;
