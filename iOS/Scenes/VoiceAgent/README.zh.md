# 对话式 AI 引擎

*Read this in other languages: [English](README.md)*

对话式 AI 引擎 ...

### 一、快速开始

这个部分主要介绍如何快速跑通对话式 AI 引擎项目

#### 1.1 环境准备

- Xcode 15 或以上版本
- iOS 15.0 或以上版本的 iPhone 设备

#### 1.2 运行项目

- 1.2.1 进入声网控制台获取 APP ID 和 APP 证书 [控制台入口](https://console.shengwang.cn/overview)

  - 点击创建项目

    ![图片](https://accktvpic.oss-cn-beijing.aliyuncs.com/pic/github_readme/ent-full/sdhy_1.jpg)
  - 选择项目基础配置, 鉴权机制需要选择**安全模式**

    ![图片](https://accktvpic.oss-cn-beijing.aliyuncs.com/pic/github_readme/ent-full/sdhy_2.jpg)
  - 拿到项目 APP ID 与 APP 证书

- 1.2.2  打开 `iOS` 项目，在项目根目录的 [KeyCenter.swift](../../KeyCenter.swift) 文件中填入获取到的声网 App ID 和 App 证书：

```
# RTC SDK key Config
#----------- AppKey --------------
static let AppId: String = <Your Agora App ID>
static let Certificate: String? = <Your Agora App Certificate>
```

4. 现在您可以使用 Xcode 运行项目，开始体验应用程序。

### 二、项目介绍

| 路径 | 描述 |
|------------------------------------------------------------------|-------------|
| [VoiceAgent/Classes/APIService/](VoiceAgent/Classes/APIService/) | AI 引擎通信的网络服务实现 |
| [VoiceAgent/Classes/Core/](VoiceAgent/Classes/Utils/) | 工具类，如消息解析，日志系统，多语言 |
| [VoiceAgent/Classes/Main/](VoiceAgent/Classes/Main/) | 主要 UI 界面和视图控制器 |
| [VoiceAgent/Classes/Manager/](VoiceAgent/Classes/Manager/) | 各种功能的管理器类，如RTC引擎，Agent，配置项，网络等 |
| [VoiceAgent/Classes/Model/](VoiceAgent/Classes/Model/) | 数据模型和实体类 |
| [VoiceAgent/Classes/VoiceAgentContext.swift](VoiceAgent/Classes/VoiceAgentEntrance) | 语音智能体模块入口 |
| [VoiceAgent/Resources/](VoiceAgent/Resources/) | 包含图片和本地化的资源文件 |
| [ChatViewController.swift](ChatViewController.swift) | 智能体交互实现类 |
| [RTCManager.swift](RTCManager.swift) | RTC实现类 |
| [AgentAPI.swift](AgentAPI.swift) | Agent网络请求实现类 |
| [AgentPreferenceManager.swift](AgentPreferenceManager.swift) | 智能体状态管理类 |

### 三、相关资料

- 查看我们的[对话式 AI 引擎文档]()了解更多详情
- 访问 [Agora SDK 示例](https://github.com/AgoraIO)获取更多教程
- 在 [Agora 开发者社区](https://github.com/AgoraIO-Community)查看开发者社区管理的代码仓库
- 如果您在集成过程中遇到问题，欢迎在 [Stack Overflow](https://stackoverflow.com/questions/tagged/agora.io) 上提问

### 四、问题反馈

如果您对示例项目有任何问题或建议，欢迎提交 issue。

### 五、License

示例项目遵循 MIT 开源协议。