# 声网对话式 AI 引擎体验应用

*Read this in other languages: [English](README.md)*

声网对话式 AI 引擎重新定义了人机交互界面，突破了传统文字交互，实现了高拟真、自然流畅的实时语音对话，让 AI 真正“开口说话”。适用于智能助手、情感陪伴、口语陪练、智能客服、智能硬件、沉浸式游戏 NPC 等创新场景。

### 一、快速开始

这个部分主要介绍如何快速跑通声网对话式 AI 引擎体验应用项目。

#### 1.1 环境准备

- 最低兼容 Android 7.0（SDK API Level 24）
- Android Studio 3.5 及以上版本
- Android 7.0 及以上的手机设备

#### 1.2 运行项目

- 1.2.1 进入声网控制台获取 APP ID 和 APP 证书 [控制台入口](https://console.shengwang.cn/overview)

  - 点击创建项目

    ![图片](https://accktvpic.oss-cn-beijing.aliyuncs.com/pic/github_readme/ent-full/sdhy_1.jpg)
  - 选择项目基础配置, 鉴权机制需要选择**安全模式**

    ![图片](https://accktvpic.oss-cn-beijing.aliyuncs.com/pic/github_readme/ent-full/sdhy_2.jpg)
  - 拿到项目 APP ID 与 APP 证书

- 1.2.2 在声网控制台给 APP ID 开启对话式 AI 引擎功能权限 [控制台入口](https://console.shengwang.cn/product/ConversationAI?tab=config)

  ![图片](https://accktvpic.oss-cn-beijing.aliyuncs.com/pic/github_readme/ent-full/ConvoAI.png)

- 1.2.3 在声网控制台获取 RESTful API 的 BASIC_AUTH_KEY 和 BASIC_AUTH_SECRET [控制台入口](https://console.shengwang.cn/settings/restfulApi)
  - 点击添加密钥

    ![图片](https://accktvpic.oss-cn-beijing.aliyuncs.com/pic/github_readme/ent-full/restful.png)
  - 下载并拿到密钥 txt 文件, 打开文件, 复制 BASIC_AUTH_KEY 和 BASIC_AUTH_SECRET

- 1.2.3 自行在 LLM 厂商官网获取 LLM 相关配置信息

- 1.2.4 自行在 TTS 厂商官网获取 TTS 相关配置信息

- 1.2.5 在项目的 [**gradle.properties**](../../gradle.properties) 里填写必须的配置信息
```
#----------- AppId --------------
CN_AG_APP_ID=<声网 App ID>
CN_AG_APP_CERTIFICATE=<声网 App 证书>

#----------- Basic Auth ---------------
BASIC_AUTH_KEY=<声网 RESTful API KEY>
BASIC_AUTH_SECRET=<声网 RESTful API SECRET>

#----------- LLM -----------
LLM_URL=<LLM 厂商 API BASE URL>
LLM_API_KEY=<LLM 厂商 API KEY>
LLM_SYSTEM_MESSAGES=<LLM Prompt 信息>
LLM_MODEL=<LLM 模型>

#----------- TTS -----------
TTS_VENDOR=<TTS 厂商>
TTS_PARAMS=<TTS 参数>
```

- 1.2.6 用 Android Studio 运行项目即可开始您的体验

### 二、 项目介绍

| 路径 | 描述 |
|------------------------------------------------------------------|-------------|
| [api/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/api) | 对话式 AI 引擎 restful 接口实现和数据模型 |
| [animation/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/animation) | 智能体交互动画效果 |
| [constant/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/constant) | 常量和枚举定义 |
| [subRender/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/subRender/v2) | 对话字幕渲染组件 |
| [rtc/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/rtc) | RTC 相关实现 |
| [ui/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/ui) | UI 组件和活动页面 |
| [utils/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/utils) | 工具类和辅助函数 |
| [CovLivingActivity.kt](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/CovLivingActivity.kt) | AI 对话主界面 |
| [CovSettingsDialog.kt](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/CovSettingsDialog.kt) | 智能体配置设置对话框 |
| [CovAgentInfoDialog.kt](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/CovAgentInfoDialog.kt) | 智能体状态信息对话框 |

### 三、相关资料

- 查看我们的 [对话式 AI 引擎文档](https://doc.shengwang.cn/doc/convoai/restful/landing-page) 了解更多详情
- 访问 [Agora SDK 示例](https://github.com/AgoraIO) 获取更多教程
- 在 [Agora 开发者社区](https://github.com/AgoraIO-Community) 查看开发者社区管理的代码仓库

### 四、问题反馈

- 集成遇到困难，该如何联系声网获取协助
  - 可以从智能客服获取帮助或联系技术支持人员 [声网支持](https://ticket.shengwang.cn/form?type_id=&sdk_product=&sdk_platform=&sdk_version=&current=0&project_id=&call_id=&channel_name=)

### 五、License
The MIT License (MIT).