# 对话式 AI 引擎

*Read this in other languages: [English](README.md)*

对话式 AI 引擎 ...

### 一、快速开始

这个部分主要介绍如何快速跑通对话式 AI 引擎项目

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

- 1.2.2 在项目的 [**gradle.properties**](../../gradle.properties) 里填写需要的声网 APP ID 和 APP 证书
```
# RTC SDK key Config
#----------- AppKey --------------
GLOBAL_AG_APP_ID=<Your Agora App ID>
GLOBAL_AG_APP_CERTIFICATE=<Your Agora App Certificate(if enable token)>

GLOBAL_AG_APP_ID_DEV=<Your Agora App ID>
GLOBAL_AG_APP_CERTIFICATE_DEV=<Your Agora App Certificate(if enable token)>

CN_AG_APP_ID=<Your Agora App ID>
CN_AG_APP_CERTIFICATE=<Your Agora App Certificate(if enable token)>

CN_AG_APP_ID_DEV<Your Agora App ID>
CN_AG_APP_CERTIFICATE_DEV=<Your Agora App Certificate(if enable token)>
```

- 1.2.3 用 Android Studio 运行项目即可开始您的体验

### 二、 项目介绍

| 路径 | 描述 |
|------------------------------------------------------------------|-------------|
| [api/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/api) | 对话式 AI 引擎 restful 接口实现和数据模型 |
| [animation/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/animation) | 智能体交互动画效果 |
| [constant/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/constant) | 常量和枚举定义 |
| [debug/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/debug) | 调试工具和设置界面 |
| [rtc/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/rtc) | RTC 相关实现 |
| [ui/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/ui) | UI 组件和活动页面 |
| [utils/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/utils) | 工具类和辅助函数 |
| [CovLivingActivity.kt](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/CovLivingActivity.kt) | AI 对话主界面 |
| [CovSettingsDialog.kt](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/CovSettingsDialog.kt) | 智能体配置设置对话框 |
| [CovAgentInfoDialog.kt](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/CovAgentInfoDialog.kt) | 智能体状态信息对话框 |

### 三、相关资料

- 查看我们的 [对话式 AI 引擎文档]() 了解更多详情
- 访问 [Agora SDK 示例](https://github.com/AgoraIO) 获取更多教程
- 在 [Agora 开发者社区](https://github.com/AgoraIO-Community) 查看开发者社区管理的代码仓库

### 四、问题反馈

- 集成遇到困难，该如何联系声网获取协助
  - 可以从智能客服获取帮助或联系技术支持人员 [声网支持](https://ticket.shengwang.cn/form?type_id=&sdk_product=&sdk_platform=&sdk_version=&current=0&project_id=&call_id=&channel_name=)

### 五、License
The MIT License (MIT).