# Conversational AI Agent

*__其他语言版本：__  [__简体中文__](README.zh.md)*

The Conversational AI Agent ...

### 1. Quick Start

This section mainly describes how to quickly run the Conversational AI Agent Demo.

#### 1.1 Environment Preparation

- Xcode 15 or higher.
- A mobile device that runs iPhone 15.0 or higher.

#### 1.2 Running the Sample

1. Follow [The Account Document](https://docs.agora.io/en/video-calling/reference/manage-agora-account) to get the **App ID** and **App Certificate**.
2. Please contact Agora technical support to grant conversational ai permission to your APPID. Only after granting permission can you properly experience the demo features.
3. Open the `iOS` project and fill in properties got above to the root [KeyCenter.swift](../../KeyCenter.swift) file. 

```
# RTC SDK key Config
#----------- AppKey --------------
static let AppId: String = <Your Agora App ID>
static let Certificate: String? = <Your Agora App Certificate>
```
4. Now you can run the project with Xcode to experience the application.

### 2. Source Code Sitemap

| Path | Description |
|------------------------------------------------------------------|-------------|
| [VoiceAgent/Classes/APIService/](VoiceAgent/Classes/APIService/) | Network service implementation for AI agent communication. |
| [VoiceAgent/Classes/Core/](VoiceAgent/Classes/Utils/) | Utility classes for message parsing, logging system, and localization. |
| [VoiceAgent/Classes/Main/](VoiceAgent/Classes/Main/) | Main UI screens and view controllers. |
| [VoiceAgent/Classes/Manager/](VoiceAgent/Classes/Manager/) | Manager classes for various functionalities, including RTC engine, Agent, configuration, and network. |
| [VoiceAgent/Classes/Model/](VoiceAgent/Classes/Model/) | Data models and entities. |
| [VoiceAgent/Classes/VoiceAgentContext.swift](VoiceAgent/Classes/VoiceAgentEntrance) | Voice agent module entry point. |
| [VoiceAgent/Resources/](VoiceAgent/Resources/) | Resource files including images and localization. |
| [ChatViewController.swift](ChatViewController.swift) | Agent interaction implementation class. |
| [RTCManager.swift](RTCManager.swift) | RTC implementation class. |
| [AgentAPI.swift](AgentAPI.swift) | Agent network request implementation class. |
| [AgentPreferenceManager.swift](AgentPreferenceManager.swift) | Agent state management class. |

### 3. Related Resources

- Check our [Conversational AI Agent Document]() to see more about Conversational AI Agent.
- Dive into [Agora SDK Samples](https://github.com/AgoraIO) to see more tutorials.
- Repositories managed by developer communities can be found at [Agora Community](https://github.com/AgoraIO-Community).
- If you encounter problems during integration, feel free to ask questions on [Stack Overflow](https://stackoverflow.com/questions/tagged/agora.io).

### 4. Feedback

If you have any problems or suggestions regarding the sample projects, feel free to file an issue.

### 5. License

The sample projects are under the MIT license.
