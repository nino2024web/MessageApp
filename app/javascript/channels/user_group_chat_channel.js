import consumer from "channels/consumer";

function currentRoomId() {
  var q = new URLSearchParams(window.location.search).get("chat_room_id");
  return q;
}
function isViewing(roomId) {
  return (
    String(currentRoomId()) === String(roomId) &&
    document.visibilityState === "visible"
  );
}
function byId(id) {
  return document.getElementById(id);
}

function dedupeByExactId(id) {
  var nodes = document.querySelectorAll('[id="' + id + '"]');
  for (var i = 0; i < nodes.length; i++) if (i > 0) nodes[i].remove();
}
function updateUnreadBadge(roomId, html) {
  var nodes = document.querySelectorAll(
    '[id="unread-count-group-' + roomId + '"]'
  );
  for (var i = 0; i < nodes.length; i++) nodes[i].innerHTML = html;
}

/* 既読確定（1秒デバウンス） */
var __lastReadAt = 0;
function markAsRead(chatRoomId) {
  var now = Date.now();
  if (!chatRoomId) return;
  if (now - __lastReadAt < 1000) return;
  __lastReadAt = now;

  var meta = document.querySelector('meta[name="csrf-token"]');
  var token = meta ? meta.getAttribute("content") : null;
  if (!token) return;

  var form = new FormData();
  form.append("chat_room_id", chatRoomId);

  fetch("/group_messages/mark_as_read", {
    method: "POST",
    headers: { "X-CSRF-Token": token, Accept: "text/html" },
    body: form,
    credentials: "same-origin",
  }).catch(function () {});
}

//  置換/招待
function handleReplaceLike(data) {
  var roomId = data.chat_room_id;
  var liId = "group-chat-item-" + roomId;
  var listId = data.current
    ? "current-group-chat-list"
    : "other-group-chat-list";

  // 同IDの重複を掃除してから差し替え
  dedupeByExactId(liId);
  var existing = byId(liId);
  var listEl = byId(listId);

  if (existing) {
    existing.outerHTML = data.html;
  } else if (listEl) {
    listEl.insertAdjacentHTML("beforeend", data.html);
  }

  // 容器の重複も差し替え
  dedupeByExactId("unread-count-group-" + roomId);

  // 表示中ならその場でバッジ空＋既読確定
  if (isViewing(roomId)) {
    updateUnreadBadge(roomId, "");
    markAsRead(roomId);
  }
}

consumer.subscriptions.create("UserGroupChatChannel", {
  connected() {},
  disconnected() {},

  received(data) {
    if (!data) return;

    switch (data.type) {
      case "update_members": {
        var countElem = byId("participant-count");
        var listElem = byId("participant-list");
        if (countElem) countElem.innerHTML = data.count_html;
        if (listElem) listElem.innerHTML = data.members_html;
        return;
      }
      case "update_inviteCandidates": {
        var wrap = byId("invite-candidates-block");
        if (wrap) wrap.innerHTML = data.html;
        return;
      }
      case "unread_count": {
        var rid = data.chat_room_id;
        var viewing = isViewing(rid);
        updateUnreadBadge(rid, viewing ? "" : data.html);
        if (viewing) markAsRead(rid);
        return;
      }
      case "replace":
      case "invited": {
        if (data.chat_room_id && data.html) handleReplaceLike(data);
        return;
      }
      case "reorder": {
        return;
      }
      case "deleted_by_creator": {
        var rid2 = data.chat_room_id;
        var li = byId("group-chat-item-" + rid2);
        if (li) li.remove();
        if (isViewing(rid2)) {
          alert(data.message);
          var uid = document.body.getAttribute("data-current-user-id");
          window.location.href = "/group/users/" + uid;
        }
        return;
      }
      default: {
        // type無しでも {chat_room_id, html} が来るケースの互換
        if (data.chat_room_id && data.html) handleReplaceLike(data);
      }
    }
  },
});
