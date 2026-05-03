const functions = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const express = require("express");

admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(express.json({ limit: "1mb" }));

let cachedAllowlist = { emails: [], fetchedAtMs: 0 };
async function getAllowlistEmails() {
  const now = Date.now();
  if (now - cachedAllowlist.fetchedAtMs < 60_000 && cachedAllowlist.emails.length) {
    return cachedAllowlist.emails;
  }
  const snap = await db.collection("adminConfig").doc("allowlist").get();
  const emails = Array.isArray(snap.data()?.emails) ? snap.data().emails : [];
  cachedAllowlist = { emails, fetchedAtMs: now };
  return emails;
}

function requireBearer(req) {
  const auth = req.get("Authorization") || "";
  const m = auth.match(/^Bearer (.+)$/);
  if (!m) {
    const err = new Error("Missing Authorization Bearer token");
    err.statusCode = 401;
    throw err;
  }
  return m[1];
}

async function requireAdmin(req) {
  const token = requireBearer(req);
  const decoded = await admin.auth().verifyIdToken(token);

  if (decoded.admin === true) {
    return decoded;
  }

  const email = decoded.email;
  if (!email) {
    const err = new Error("Admin email required");
    err.statusCode = 403;
    throw err;
  }
  const allowlist = await getAllowlistEmails();
  if (!allowlist.includes(email)) {
    const err = new Error("Not allowed");
    err.statusCode = 403;
    throw err;
  }
  return decoded;
}

async function writeAudit({ adminUid, adminEmail, action, roomId, meta }) {
  await db.collection("adminAudit").add({
    adminUid,
    adminEmail: adminEmail || "",
    action,
    roomId: roomId || "",
    meta: meta || {},
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
}

function serializeTimestamp(value) {
  if (!value) return null;
  if (value.toDate) return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  return null;
}

function serializeChatRoom(doc) {
  const d = doc.data() || {};
  return {
    roomId: d.roomId || doc.id,
    members: Array.isArray(d.members) ? d.members : [],
    updatedAt: serializeTimestamp(d.updatedAt),
    lastMessageAt: serializeTimestamp(d.lastMessageAt),
    lastMessageType: d.lastMessageType || null,
    lastMessageText: d.lastMessageText || "",
    lastMessageSenderId: d.lastMessageSenderId || null,
    lastReadAtByUser: d.lastReadAtByUser || {}
  };
}

function serializeMessage(doc) {
  const d = doc.data() || {};
  return {
    messageId: d.messageId || doc.id,
    senderId: d.senderId,
    type: d.type,
    text: d.text || null,
    imageUrl: d.imageUrl || null,
    createdAt: serializeTimestamp(d.createdAt),
    clientCreatedAt: serializeTimestamp(d.clientCreatedAt)
  };
}

app.get("/api/me", async (req, res) => {
  try {
    const decoded = await requireAdmin(req);
    res.json({
      uid: decoded.uid,
      email: decoded.email || "",
      claims: decoded
    });
  } catch (e) {
    res.status(e.statusCode || 500).json({ error: String(e.message || e) });
  }
});

app.get("/api/chatRooms", async (req, res) => {
  try {
    const decoded = await requireAdmin(req);

    const limit = Math.min(parseInt(req.query.limit || "50", 10) || 50, 200);
    const snapshot = await db.collection("chatRooms").orderBy("updatedAt", "desc").limit(limit).get();
    const rooms = snapshot.docs.map(serializeChatRoom);

    const allUids = Array.from(new Set(rooms.flatMap((r) => r.members))).filter(Boolean);
    const userDocs = await Promise.all(
      allUids.map((uid) => db.collection("users").doc(uid).get())
    );
    const usersByUid = {};
    for (const u of userDocs) {
      if (!u.exists) continue;
      const d = u.data() || {};
      usersByUid[u.id] = {
        uid: d.uid || u.id,
        name: d.name || "",
        gender: d.gender || "",
        profileImageUrl: d.profileImageUrl || ""
      };
    }

    await writeAudit({
      adminUid: decoded.uid,
      adminEmail: decoded.email,
      action: "list_chatRooms",
      roomId: "",
      meta: { limit }
    });

    res.json({ rooms, usersByUid });
  } catch (e) {
    res.status(e.statusCode || 500).json({ error: String(e.message || e) });
  }
});

app.get("/api/chatRooms/:roomId/messages", async (req, res) => {
  try {
    const decoded = await requireAdmin(req);
    const roomId = req.params.roomId;
    const limit = Math.min(parseInt(req.query.limit || "50", 10) || 50, 200);

    const roomSnap = await db.collection("chatRooms").doc(roomId).get();
    if (!roomSnap.exists) {
      res.status(404).json({ error: "Room not found" });
      return;
    }

    const msgSnap = await db
      .collection("chatRooms")
      .doc(roomId)
      .collection("messages")
      .orderBy("createdAt", "desc")
      .limit(limit)
      .get();

    const messagesDesc = msgSnap.docs.map(serializeMessage);
    const messages = messagesDesc.reverse();

    await writeAudit({
      adminUid: decoded.uid,
      adminEmail: decoded.email,
      action: "view_messages",
      roomId,
      meta: { limit }
    });

    res.json({ room: serializeChatRoom(roomSnap), messages });
  } catch (e) {
    res.status(e.statusCode || 500).json({ error: String(e.message || e) });
  }
});

exports.adminApi = onRequest(
  {
    region: "asia-northeast1",
    cors: false
  },
  app
);

