# Digital Twin App Configuration Guide

## 🧠 Introduction

**Digital Twin App** is an AI-powered assistant designed to enhance your digital experience by integrating with your communication platforms such as Slack, Telegram, email, and more. It collects and processes relevant contextual data to provide deeper insights, automate tasks, and streamline your workflow.

Digital Twin App leverages connected services to give users a richer and more accurate understanding of their digital interactions. It acts as your "digital twin," learning from your data in a secure, localized manner to help you make smarter decisions and access the right information at the right time.

---

## ⚙️ Configuration

### 1. GraphQL Server Default URL

By default, the Digital Twin App expects the GraphQL server to be available at:

http://localhost:4000/


Make sure this server is running before launching the Digital Twin App.

---

### 2. Dynamic Server Configuration via QR Code

The server URL can also be dynamically updated by scanning a QR code within the app.

The QR code must contain a JSON payload with the following format:

```json
{
  "apiURL": "https://5d69-2600-6c52-68f0-3620-1925-f6c3-ef73-e6b2.ngrok-free.app"
}

```

Once scanned, the app will switch its GraphQL endpoint to the one specified in the apiURL field.

### 3. Running the GraphQL Mock Server
To start the mock GraphQL server:

Navigate to the graphql-mock-server directory.
Run the following command:
node index.js
Ensure that no other process is using port 4000.



### 4. Ollama Integration
The GraphQL server should be connected to Ollama 3, which must be running at:

http://localhost:11434
Make sure Ollama 3 is active and accessible before launching the mock server. This connection powers the AI reasoning and response capabilities used by Digital Twin App.

### 📝 Notes

The Digital Twin App is designed to run entirely locally.
The QR code functionality allows easy switching between development, staging, and production environments or to simply select the url to use GraphQL.
Always keep Ollama and the mock server in sync for consistent performance.

