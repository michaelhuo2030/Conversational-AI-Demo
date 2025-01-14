# Agora & OpenAI Demo

An intelligent conversation demo built with Agora Real-time Communication SDK and OpenAI API.

## 🎥 Demo Preview

<div align="center" style="display: flex; flex-wrap: wrap; gap: 20px; justify-content: center;">
    <img src="demo_preview.jpg" alt="Demo preview of the conversation interface" width="45%" max-width="400px" />
    <img src="demo_preview1.jpg" alt="Demo preview of additional features" width="45%" max-width="400px" />
</div>

## ✨ Features

- Real-time Voice Communication
- AI-powered Responses
- High-quality Audio Transmission
- Low-latency Interaction

## 🏗 Architecture

<!-- <img src="./architecture.png" alt="architecture" width="700" height="400" /> -->
<picture>
  <source srcset="architecture-dark-theme.png" media="(prefers-color-scheme: dark)">
  <img src="architecture-light-theme.png" alt="Architecture diagram of Conversational Ai by Agora and OpenAi">
</picture>

## 💻 Core Components
- **KeyCenter.swift**: Project configuration management
- **AgentAPIService.swift**: Core Agent interface definitions
- **AgentManager.swift**: RTC and Agent lifecycle management
- **ChatViewController.swift**: Voice chat interface implementation

## 🚀 Getting Started

### Requirements

- iOS 13.0+
- Xcode 15.0+

### Configuration

1. Get your [Agora App ID](https://docs.agora.io/en/video-calling/get-started/manage-agora-account?platform=web#create-an-agora-project) 
2. If security mode is enabled, obtain your [App Certificate](https://docs.agora.io/en/video-calling/get-started/manage-agora-account?platform=web#create-an-agora-project)

### Run the Project
1. Clone the repository
2. Enter the directory of iOS and run the following command
```
	pod install
```
3. Open Agent.xcworkspace with Xcode
4. Open KeyCenter.swift and configure your Agora credentials:
```
	static let AppId: String = <#YOUR APPID#>
	static let AppId: String = <#YOUR APPID#>
```
5. Run the project

### How to Connect to your own service
You can also connect to your own server.
Modify the following configuration in KeyCenter.swift and fill in your own host
```
	static let BaseHostUrl: String = <#YOUR HOST#>
```
### Server Example

- [openai-realtime-python](https://github.com/AgoraIO/openai-realtime-python/)

## 📄 License

This project is open-sourced under the Apache 2.0 license - see the [LICENSE](LICENSE) file for details.
