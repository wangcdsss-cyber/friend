import admin from "firebase-admin";
import pLimit from "p-limit";
import yargs from "yargs";
import { hideBin } from "yargs/helpers";

const argv = yargs(hideBin(process.argv))
  .option("projectId", { type: "string", default: process.env.FIREBASE_PROJECT_ID || "demo-friend" })
  .option("rooms", { type: "number", default: 50 })
  .option("messagesPerRoom", { type: "number", default: 50 })
  .option("concurrency", { type: "number", default: 50 })
  .option("users", { type: "number", default: 100 })
  .option("dryRun", { type: "boolean", default: false })
  .strict()
  .parseSync();

function nowMs() {
  return Date.now();
}

function randomInt(max) {
  return Math.floor(Math.random() * max);
}

function pickTwoDistinct(arr) {
  const a = arr[randomInt(arr.length)];
  let b = arr[randomInt(arr.length)];
  while (b === a) b = arr[randomInt(arr.length)];
  return [a, b].sort();
}

function roomIdFor(uidA, uidB) {
  return `${uidA}_${uidB}`;
}

function messagePayload(messageId, senderId, text) {
  return {
    messageId,
    senderId,
    type: "text",
    text,
    clientCreatedAt: new Date(),
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  };
}

function roomUpdatePayload(senderId, lastMessageText) {
  const ts = admin.firestore.FieldValue.serverTimestamp();
  return {
    updatedAt: ts,
    lastMessageAt: ts,
    lastMessageType: "text",
    lastMessageText,
    lastMessageSenderId: senderId
  };
}

async function init() {
  const useEmulator = !!process.env.FIRESTORE_EMULATOR_HOST;
  if (useEmulator) {
    admin.initializeApp({ projectId: argv.projectId });
  } else {
    admin.initializeApp({
      projectId: argv.projectId,
      credential: admin.credential.applicationDefault()
    });
  }
  return admin.firestore();
}

async function main() {
  const db = await init();
  const limit = pLimit(argv.concurrency);

  const userIds = Array.from({ length: argv.users }, (_, i) => `loadtest_user_${i}`);
  const pairs = Array.from({ length: argv.rooms }, () => pickTwoDistinct(userIds));

  const t0 = nowMs();
  let okWrites = 0;
  let failWrites = 0;
  let latencies = [];

  const tasks = [];

  for (const [uidA, uidB] of pairs) {
    const roomId = roomIdFor(uidA, uidB);
    const roomRef = db.collection("chatRooms").doc(roomId);
    const members = [uidA, uidB];

    tasks.push(limit(async () => {
      const start = nowMs();
      try {
        if (!argv.dryRun) {
          await roomRef.set(
            {
              roomId,
              members,
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
            },
            { merge: true }
          );
        }
        okWrites += 1;
        latencies.push(nowMs() - start);
      } catch {
        failWrites += 1;
      }
    }));

    for (let i = 0; i < argv.messagesPerRoom; i += 1) {
      const senderId = Math.random() < 0.5 ? uidA : uidB;
      const text = `loadtest ${roomId} #${i}`;

      tasks.push(limit(async () => {
        const start = nowMs();
        try {
          if (!argv.dryRun) {
            const msgRef = roomRef.collection("messages").doc();
            const batch = db.batch();
            batch.set(msgRef, messagePayload(msgRef.id, senderId, text));
            batch.set(roomRef, roomUpdatePayload(senderId, text), { merge: true });
            await batch.commit();
          }
          okWrites += 1;
          latencies.push(nowMs() - start);
        } catch {
          failWrites += 1;
        }
      }));
    }
  }

  await Promise.all(tasks);

  const totalMs = nowMs() - t0;
  latencies.sort((a, b) => a - b);
  const p50 = latencies[Math.floor(latencies.length * 0.5)] ?? 0;
  const p90 = latencies[Math.floor(latencies.length * 0.9)] ?? 0;
  const p99 = latencies[Math.floor(latencies.length * 0.99)] ?? 0;

  const totalOps = okWrites + failWrites;
  const opsPerSec = totalMs > 0 ? (totalOps * 1000) / totalMs : 0;

  process.stdout.write(
    JSON.stringify(
      {
        projectId: argv.projectId,
        rooms: argv.rooms,
        messagesPerRoom: argv.messagesPerRoom,
        concurrency: argv.concurrency,
        dryRun: argv.dryRun,
        totalOps,
        okWrites,
        failWrites,
        totalMs,
        opsPerSec: Number(opsPerSec.toFixed(2)),
        latencyMs: { p50, p90, p99 }
      },
      null,
      2
    ) + "\n"
  );
}

main().catch((e) => {
  process.stderr.write(String(e?.stack || e) + "\n");
  process.exit(1);
});

