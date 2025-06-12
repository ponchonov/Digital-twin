const { GraphQLDateTime, GraphQLJSON } = require('graphql-scalars');
const fetch = require('node-fetch'); // at the top if not already imported

// Utility to randomly assign 0–3 image URLs
const getRandomImageUrls = () => {
  const imagePool = [
    'https://static.vecteezy.com/system/resources/thumbnails/036/324/708/small/ai-generated-picture-of-a-tiger-walking-in-the-forest-photo.jpg',
    'https://images.ctfassets.net/hrltx12pl8hq/28ECAQiPJZ78hxatLTa7Ts/2f695d869736ae3b0de3e56ceaca3958/free-nature-images.jpg?fit=fill&w=1200&h=630',
    'https://static.wixstatic.com/media/aa8751_0e2a1faaf9b241e0a9c988fb02987757~mv2.jpg/v1/crop/x_0,y_24,w_1080,h_1033/fill/w_256,h_256,al_c,q_80,usm_0.66_1.00_0.01,enc_avif,quality_auto/451833026_302026266270726_333130077128278713_n.jpg',
    'https://pbs.twimg.com/profile_images/632568635970576384/uTvv9oXs_400x400.jpg'
  ];

  const shuffled = [...imagePool].sort(() => 0.5 - Math.random());
  const count = Math.floor(Math.random() * 4); // 0 to 3
  return shuffled.slice(0, count);
};

// Generate 30 mock chats with 5 alternating USER/ASSISTANT messages
const generateMockChats = () => {
  const chats = [];

  for (let i = 1; i <= 30; i++) {
    const messages = [];

    for (let j = 1; j <= 5; j++) {
      const userMessage = {
        id: `msg-${i}-${j}-user`,
        text: `User message ${j} in Chat ${i}`,
        imageUrls: getRandomImageUrls(),
        role: 'USER',
        toolCalls: [],
        toolResults: [],
        createdAt: new Date(Date.now() - (5 - j) * 60000).toISOString()
      };

      const assistantMessage = {
        id: `msg-${i}-${j}-assistant`,
        text: `Assistant reply ${j} in Chat ${i}`,
        imageUrls: getRandomImageUrls(),
        role: 'ASSISTANT',
        toolCalls: [],
        toolResults: [],
        createdAt: new Date(Date.now() - (5 - j) * 60000 + 30000).toISOString()
      };

      messages.push(userMessage, assistantMessage);
    }

    const chat = {
      id: `chat-${i}`,
      name: `Mock Chat ${i}`,
      messages,
      createdAt: new Date().toISOString()
    };

    chats.push(chat);
  }

  return chats;
};

const mockChats = generateMockChats();

module.exports = {
  DateTime: GraphQLDateTime,
  JSON: GraphQLJSON,

  Query: {
    profile: () => ({ name: 'John Doe', bio: 'Just a test user.' }),
    getChats: (_, { first = 10, offset = 0 }) => mockChats.slice(offset, offset + first),
    getChat: (_, { id }) => mockChats.find(chat => chat.id === id)
  },

  Mutation: {
    updateProfile: (_, { input }) => true,
   sendMessage: async (_, { chatId, text }) => {
  const chat = mockChats.find(c => c.id === chatId);
  if (!chat) return null;

  // Create and add the USER message
  const userMessage = {
    id: `msg-${Math.random().toString(36).substr(2, 5)}`,
    text,
    imageUrls: [],
    role: 'USER',
    toolCalls: [],
    toolResults: [],
    createdAt: new Date().toISOString()
  };

  chat.messages.push(userMessage);

  try {
    // Construct the prompt from previous conversation if needed
    const prompt = chat.messages.map(m => `${m.role === 'USER' ? 'User' : 'Assistant'}: ${m.text}`).join('\n') + `\nAssistant:`;

    // Send to Ollama
    const response = await fetch('http://localhost:11434/api/generate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'llama3',
        prompt,
        stream: false
      })
    });

    const result = await response.json();

    // Create ASSISTANT message from Ollama response
    const assistantMessage = {
      id: `msg-${Math.random().toString(36).substr(2, 5)}`,
      text: result.response.trim(),
      imageUrls: [],
      role: 'ASSISTANT',
      toolCalls: [],
      toolResults: [],
      createdAt: new Date().toISOString()
    };

    chat.messages.push(assistantMessage);

    // Return the USER message
    return assistantMessage;
  } catch (err) {
    console.error('Error calling Ollama:', err);
    userMessage.text = 'no response'
    userMessage.role = 'ASSISTANT'
    return userMessage; // Still return USER message even if AI fails
  }
},
    createChat: (_, { name }) => {
      const newChat = {
        id: `chat-${mockChats.length + 1}`,
        name,
        messages: [],
        createdAt: new Date().toISOString()
      };
      mockChats.push(newChat);
      return newChat;
    },
    deleteChat: (_, { chatId }) => {
      const index = mockChats.findIndex(c => c.id === chatId);
      if (index === -1) return null;
      return mockChats.splice(index, 1)[0];
    }
  },

  Subscription: {
    messageAdded: {
      subscribe: () => null
    },
    toolCallUpdated: {
      subscribe: () => null
    }
  }
};
