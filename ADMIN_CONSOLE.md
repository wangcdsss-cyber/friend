# 管理后台（Firebase Hosting + 邮箱登录）

该后台用于在云端查看 `chatRooms` / `messages`（含图片 URL），并对查看行为写入 `adminAudit` 审计日志。

## 1) 前置条件

- 已有 Firebase 项目（与 iOS App 同一个项目）
- 已启用 **Authentication → Email/Password**
- 本机已安装 Firebase CLI 并登录：`firebase login`

## 2) 配置允许的管理员（强烈建议）

在 Firestore 创建文档：

- Collection：`adminConfig`
- Document：`allowlist`
- 字段：`emails`（Array）

示例：

```json
{
  "emails": ["admin@example.com", "ops@example.com"]
}
```

说明：Cloud Functions 会校验 `ID Token`，要求邮箱存在且在 allowlist 内（或 Token 自带 `admin: true` claim）。

## 3) 部署

1. 在仓库根目录（包含 `firebase.json` 的目录）填写项目 ID：
   - 编辑 [.firebaserc](file:///Users/shihou/app/friend/friend/.firebaserc) 将 `YOUR_FIREBASE_PROJECT_ID` 改成你的项目 ID

2. 安装 Functions 依赖：

```bash
cd functions
npm install
```

3. 部署 Functions + Hosting：

```bash
cd ..
firebase deploy --only functions:adminApi,hosting
```

部署完成后，Firebase CLI 会输出 Hosting URL，在浏览器打开即可。

## 4) 使用

- 用 Firebase Auth 的邮箱/密码登录
- 左侧会话列表 → 点击会话 → 右侧查看消息
- 图片消息会以图片形式展示（来自 Storage 的下载 URL）

## 5) 审计日志

后台每次拉取会话/消息都会写入：

- Collection：`adminAudit`
  - `adminUid`
  - `adminEmail`
  - `action`（`list_chatRooms` / `view_messages`）
  - `roomId`
  - `createdAt`

## 6) 安全注意事项

- 后台不应公开给普通用户；只应让少量管理员访问
- 不要把任何 Service Account Key 提交进仓库
- 若要更严格：建议配合自定义域名 + 基于 Google Cloud Armor/IP 白名单（进阶）

