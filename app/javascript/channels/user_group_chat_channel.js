import consumer from "channels/consumer";

function currentRoomId() {
  return new URLSearchParams(location.search).get("chat_room_id");
}
function isViewing(roomId) {
  return String(currentRoomId()) === String(roomId) && document.visibilityState === "visible";
}

consumer.subscriptions.create("UserGroupChatChannel", {
  connected() {},
  disconnected() {},
  received(data) {
    // メンバー表示
    if (data.type === "update_members") {
      const countElem = document.querySelector("#participant-count");
      const listElem  = document.querySelector("#participant-list");
      if (countElem) countElem.innerHTML = data.count_html;
      if (listElem)  listElem.innerHTML  = data.members_html;
    }

    // 招待候補
    if (data.type === "update_inviteCandidates") {
      const wrapper = document.getElementById("invite-candidates-block");
      if (wrapper) wrapper.innerHTML = data.html;
    }

    // チャット項目の追加/更新
    if (data.type === "invited" || (data.chat_room_id && data.html)) {
      const id = `group-chat-item-${data.chat_room_id}`;
      const existing = document.getElementById(id);
      const targetList = data.current ? "current-group-chat-list" : "other-group-chat-list";

      if (existing) {
        existing.outerHTML = data.html;
      } else {
        document.getElementById(targetList)?.insertAdjacentHTML("beforeend", data.html);
      }

      // 表示中の部屋なら、置換後に未読バッジを空に
      if (isViewing(data.chat_room_id)) {
        const badgeWrap = document.getElementById(`unread-count-group-${data.chat_room_id}`);
        if (badgeWrap) badgeWrap.innerHTML = "";
      }
    }

    if (data.type === "unread_count") {
      const items = document.querySelectorAll(`#group-chat-item-${data.chat_room_id}`);
      items.forEach((li) => {
        const box = li.querySelector(`#unread-count-group-${data.chat_room_id}`);
        if (!box) return;
        box.innerHTML = isViewing(data.chat_room_id) ? "" : data.html;
      });
    }
    

    // チャット項目の全置換
    if (data.type === "replace") {
      const id = `group-chat-item-${data.chat_room_id}`;
      const elem = document.getElementById(id);
      if (elem) elem.outerHTML = data.html;

      if (isViewing(data.chat_room_id)) {
        const badgeWrap = document.getElementById(`unread-count-group-${data.chat_room_id}`);
        if (badgeWrap) badgeWrap.innerHTML = "";
      }
    }

    // 作成者による削除通知
    if (data.type === "deleted_by_creator") {
      document.getElementById(`group-chat-item-${data.chat_room_id}`)?.remove();
      // 表示中だったら移動
      if (isViewing(data.chat_room_id)) {
        alert(data.message);
        const uid = document.body.dataset.currentUserId;
        window.location.href = `/group/users/${uid}`;
      }
    }
  },
});
