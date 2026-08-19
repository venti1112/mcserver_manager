# Minecraft 服务器管理工具

一款基于 Flutter 开发的 Minecraft 服务器远程管理工具，通过 RCON 协议实现服务器状态监控和玩家管理。

## 功能特性

- 🔐 **安全连接**：支持 RCON 协议，密码加密存储
- 👥 **实时监控**：查看在线人数和玩家列表
- 🛡️ **权限管理**：授予/撤销玩家 OP 权限
- 🚫 **玩家控制**：踢出、封禁玩家
- 💻 **远程控制台**：执行任意服务器命令
- 📱 **移动端优化**：适配手机操作习惯

## 快速开始

### 环境要求

- Flutter SDK 3.0+
- Android 7.0+

### 构建步骤

```bash
# 克隆项目
git clone https://github.com/venti1112/mcserver_manager.git
cd mcserver_manager

# 安装依赖
flutter pub get

# 构建 APK
flutter build apk --release