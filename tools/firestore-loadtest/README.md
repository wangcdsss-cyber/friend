## Firestore 高并发压测（Load Test）

该工具用于对 `chatRooms + messages` 写入路径做并发压测，输出吞吐量与延迟分位数（p50/p90/p99）。

### 1) 依赖安装

在该目录执行：

```bash
npm install
```

### 2) 使用 Firebase Emulator（推荐）

先启动 Emulator（示例端口：Firestore 8080）后，执行：

```bash
FIRESTORE_EMULATOR_HOST=localhost:8080 \
FIREBASE_PROJECT_ID=demo-friend \
npm run loadtest -- --rooms 100 --messagesPerRoom 200 --concurrency 100
```

### 3) 压测生产/测试环境（需要凭证）

不要把任何密钥提交进仓库。通过环境变量提供 ADC 凭证：

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/absolute/path/to/service-account.json"
export FIREBASE_PROJECT_ID="your-project-id"

npm run loadtest -- --rooms 100 --messagesPerRoom 200 --concurrency 100
```

### 输出示例

工具输出 JSON，例如：

```json
{
  "totalOps": 20100,
  "okWrites": 20100,
  "failWrites": 0,
  "totalMs": 12345,
  "opsPerSec": 1627.4,
  "latencyMs": { "p50": 18, "p90": 55, "p99": 130 }
}
```

