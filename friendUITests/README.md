## 端到端（E2E）UI 测试

本目录提供 XCUITest 用例，依赖应用内的可访问性标识符：
- 聊天列表：`chatList`
- 会话行：`conversationRow_<roomId>`
- 聊天输入框：`messageInput`
- 发送按钮：`sendButton`
- 图片入口按钮：`mediaButton`

### 在 Xcode 中启用（一次性）
1. Xcode → File → New → Target… → iOS → UI Testing Bundle
2. Target 名称建议：`friendUITests`
3. 将本目录 `friendUITests/ChatE2ETests.swift` 加入该 Target（右侧 File Inspector → Target Membership 勾选）

### 运行方式
1. 先在模拟器里完成一次登录，并确保聊天列表至少有 1 个会话（已有会话即可）
2. Xcode → Test Navigator → 运行 `ChatE2ETests`

### 使用 Emulator（可选）
若要跑在 Firebase Emulator 上，建议在 Scheme 的 Environment Variables 配置：
- `USE_FIREBASE_EMULATOR=1`
- `FIRESTORE_EMULATOR_HOST=localhost`
- `FIRESTORE_EMULATOR_PORT=8080`
- `STORAGE_EMULATOR_HOST=localhost`
- `STORAGE_EMULATOR_PORT=9199`

