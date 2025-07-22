import consumer from "channels/consumer";

consumer.subscriptions.create("UserGroupChatChannel", {
  connected() {
    console.log("✅ UserGroupChatChannel connected");
  },

  disconnected() {},

  received(data) {
    console.log("📩 受信:", data);

    // メンバー表示の更新（人数とリスト）
    if (data.type === "update_members") {
      const countElem = document.querySelector("#participant-count");
      const listElem = document.querySelector("#participant-list");

      if (countElem) countElem.innerHTML = data.count_html;
      if (listElem) listElem.innerHTML = data.members_html;
    }

    // 招待候補の更新
    if (data.type === "update_inviteCandidates") {
      const wrapper = document.getElementById("group-invite-wrapper");
      if (wrapper) {
        wrapper.innerHTML = data.html;
      } else {
        console.warn("group-invite-formが見つからない");
      }
    }

    // チャット項目（左側リスト）の更新
    if (data.type === "invited" || (data.chat_room_id && data.html)) {
      const id = `group-chat-item-${data.chat_room_id}`;
      const existing = document.getElementById(id);

      const targetList = data.current
        ? "current-group-chat-list"
        : "other-group-chat-list";

      if (existing) {
        existing.outerHTML = data.html;
      } else {
        const list = document.getElementById(targetList);
        if (list) list.insertAdjacentHTML("beforeend", data.html);
      }
    }
  },
});
