function qs(id) {
  return document.getElementById(id);
}

function escapeHtml(s) {
  return String(s || "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function fmtTime(iso) {
  if (!iso) return "";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  return d.toLocaleString();
}

async function apiGet(path) {
  const user = firebase.auth().currentUser;
  if (!user) throw new Error("Not signed in");
  const token = await user.getIdToken();
  const res = await fetch(path, {
    headers: { Authorization: `Bearer ${token}` }
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(json.error || `HTTP ${res.status}`);
  return json;
}

const state = {
  rooms: [],
  usersByUid: {},
  selectedRoomId: null
};

function renderRooms() {
  const el = qs("rooms");
  el.innerHTML = "";

  for (const room of state.rooms) {
    const names = (room.members || [])
      .map((uid) => state.usersByUid[uid]?.name || uid)
      .join(" / ");
    const last = room.lastMessageType === "image" ? "[图片]" : (room.lastMessageText || "");
    const time = fmtTime(room.lastMessageAt || room.updatedAt);

    const div = document.createElement("div");
    div.className = "room";
    div.dataset.roomId = room.roomId;
    div.innerHTML = `
      <div class="room-title">
        <div class="room-name">${escapeHtml(names || room.roomId)}</div>
        <div class="muted">${escapeHtml(time)}</div>
      </div>
      <div class="room-sub">${escapeHtml(last)}</div>
      <div class="muted">roomId: ${escapeHtml(room.roomId)}</div>
    `;
    div.addEventListener("click", () => selectRoom(room.roomId));
    el.appendChild(div);
  }
}

function renderMessages(room, messages) {
  qs("roomTitle").textContent = "消息";
  qs("roomMeta").textContent = room ? `roomId: ${room.roomId}` : "";

  const el = qs("messages");
  el.innerHTML = "";

  for (const m of messages) {
    const head = document.createElement("div");
    head.className = "msg";

    const created = fmtTime(m.createdAt || m.clientCreatedAt);
    head.innerHTML = `
      <div class="msg-head">
        <div>${escapeHtml(m.senderId || "")}</div>
        <div>${escapeHtml(created)}</div>
      </div>
    `;

    if (m.type === "image" && m.imageUrl) {
      const img = document.createElement("img");
      img.className = "msg-img";
      img.src = m.imageUrl;
      img.alt = "image";
      img.loading = "lazy";
      head.appendChild(img);
    } else {
      const txt = document.createElement("div");
      txt.className = "msg-text";
      txt.textContent = m.text || "";
      head.appendChild(txt);
    }

    el.appendChild(head);
  }
}

async function loadRooms() {
  const data = await apiGet("/api/chatRooms?limit=100");
  state.rooms = data.rooms || [];
  state.usersByUid = data.usersByUid || {};
  renderRooms();
}

async function selectRoom(roomId) {
  state.selectedRoomId = roomId;
  const data = await apiGet(`/api/chatRooms/${encodeURIComponent(roomId)}/messages?limit=200`);
  const room = data.room;
  const messages = data.messages || [];
  qs("roomTitle").textContent = "消息";
  const names = (room.members || []).map((uid) => state.usersByUid[uid]?.name || uid).join(" / ");
  qs("roomTitle").textContent = names || roomId;
  qs("roomMeta").textContent = `roomId: ${roomId}`;
  renderMessages(room, messages);
}

function showLoginError(msg) {
  qs("loginError").textContent = msg || "";
}

function setSignedIn(user) {
  qs("loginPanel").hidden = !!user;
  qs("dashboard").hidden = !user;
  qs("logoutBtn").hidden = !user;
  qs("me").textContent = user ? (user.email || user.uid) : "";
}

async function onLogin() {
  showLoginError("");
  const email = qs("email").value.trim();
  const password = qs("password").value;
  if (!email || !password) {
    showLoginError("请输入邮箱和密码");
    return;
  }
  try {
    await firebase.auth().signInWithEmailAndPassword(email, password);
  } catch (e) {
    showLoginError(e?.message || "登录失败");
  }
}

async function onLogout() {
  await firebase.auth().signOut();
}

async function init() {
  qs("loginBtn").addEventListener("click", onLogin);
  qs("logoutBtn").addEventListener("click", onLogout);
  qs("refreshBtn").addEventListener("click", () => loadRooms().catch((e) => alert(e.message)));

  firebase.auth().onAuthStateChanged(async (user) => {
    setSignedIn(user);
    if (user) {
      try {
        await apiGet("/api/me");
        await loadRooms();
      } catch (e) {
        alert(e.message || String(e));
        await firebase.auth().signOut();
      }
    }
  });
}

window.addEventListener("load", init);

