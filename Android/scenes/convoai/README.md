# Conversational AI Agent

*__其他语言版本：__  [__简体中文__](README.zh.md)*

The Conversational AI Agent ...

### 1. Quick Start

This section mainly describes how to quickly run the Conversational AI Agent Demo.

#### 1.1 Environment Preparation

- Minimum compatibility with Android 7.0 (SDK API Level 24)
- Android Studio 3.5 or above
- Android devices running Android 7.0 or above

#### 1.2 Running the Sample

1. Follow [The Account Document](https://docs.agora.io/en/video-calling/reference/manage-agora-account) to get the **App ID** and **App Certificate**.
2. Please contact Agora technical support to grant conversational ai permission to your APPID. Only after granting permission can you properly experience the demo features.
3. Open the `Android` project and fill in properties got above to the root [**gradle.properties**](../../gradle.properties) file.

```
# RTC SDK key Config
#----------- AppKey --------------
GLOBAL_AG_APP_ID=<Your Agora App ID>
GLOBAL_AG_APP_CERTIFICATE=<Your Agora App Certificate>

GLOBAL_AG_APP_ID_DEV=<Your Agora App ID>
GLOBAL_AG_APP_CERTIFICATE_DEV=<Your Agora App Certificate>

CN_AG_APP_ID=<Your Agora App ID>
CN_AG_APP_CERTIFICATE=<Your Agora App Certificate>

CN_AG_APP_ID_DEV<Your Agora App ID>
CN_AG_APP_CERTIFICATE_DEV=<Your Agora App Certificate>
```

### 2. Source Code Sitemap

| Path | Description |
|------------------------------------------------------------------|-------------|
| [api/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/api) | Conversational AI API implementation and models. |
| [animation/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/animation) | Animation effects for agent interaction. |
| [constant/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/constant) | Constants and enums definition. |
| [debug/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/debug) | Debug tools and settings UI. |
| [rtc/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/rtc) | RTC related implementations. |
| [ui/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/ui) | UI components and activities. |
| [utils/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/utils) | Utility classes and helper functions. |
| [CovLivingActivity.kt](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/CovLivingActivity.kt) | Main activity for AI conversation. |
| [CovSettingsDialog.kt](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/CovSettingsDialog.kt) | Settings dialog for agent configuration. |
| [CovAgentInfoDialog.kt](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/CovAgentInfoDialog.kt) | Information dialog showing agent status. |

### 3. Related Resources

- Check our [Conversational AI Agent Document]() to see more about Conversational AI Agent.
- Dive into [Agora SDK Samples](https://github.com/AgoraIO) to see more tutorials.
- Repositories managed by developer communities can be found at [Agora Community](https://github.com/AgoraIO-Community).
- If you encounter problems during integration, feel free to ask questions on [Stack Overflow](https://stackoverflow.com/questions/tagged/agora.io).

### 4. Feedback

If you have any problems or suggestions regarding the sample projects, feel free to file an issue.

### 5. License

The sample projects are under the MIT license.
