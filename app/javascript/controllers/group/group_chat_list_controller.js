import { Controller } from "@hotwired/stimulus";
import consumer from "../../channels/consumer";

export default class extends Controller {
  static values = { chatRoomId: Number, userId: Number };

  connect() {
    // 既存処理があれば残す
    this.subscription = consumer.subscriptions.create(
      { channel: "UserGroupChatChannel" },
      {
        received: (data) => {
          if (data.type === "replace") this.replaceItem(data);
          if (data.type === "reorder") this.moveToTop(data.chat_room_id);
        },
      }
    );
  }

  disconnect() {
    if (this.subscription) consumer.subscriptions.remove(this.subscription);
  }

  replaceItem({ chat_room_id, html }) {
    const li = document.getElementById(`group-chat-item-${chat_room_id}`);
    if (li) {
      li.outerHTML = html;
    }
  }

  moveToTop(chatRoomId) {
    const li = document.getElementById(`group-chat-item-${chatRoomId}`);
    const list = li?.parentElement;
    if (li && list) list.prepend(li);
  }

  // header-クリック系
  confirmLeave(e) {
    const groupChatId = e.currentTarget.dataset.groupChatId;
    if (confirm("本当に退会しますか？")) this.leaveGroup(groupChatId);
  }

  confirmDelete(e) {
    const groupChatId = e.currentTarget.dataset.groupChatId;
    if (confirm("本当にグループチャットを削除しますか？")) {
      this.leaveGroup(groupChatId);
    }
  }

  async leaveGroup(groupChatId) {
    const res = await fetch(`/group_chats/${groupChatId}`, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": document
          .querySelector("meta[name='csrf-token']")
          ?.getAttribute("content"),
        Accept: "application/json",
      },
    });

    if (res.ok) {
      // ローカルだけで消す（サーバからの通知も来るが、二重でも安全）
      this.removeGroupChatFromDOM(groupChatId);

      // 表示中ならリダイレクト
      if (Number(this.chatRoomIdValue) === parseInt(groupChatId, 10)) {
        window.location.href = `/group/users/${this.userIdValue}`;
      }
    } else {
      alert("処理に失敗しました。時間をおいて再度お試しください。");
    }
  }

  // 共通DOM操作
  removeGroupChatFromDOM(groupChatId) {
    document.querySelector(`#group-chat-item-${groupChatId}`)?.remove();
    document.querySelector(".group-center-area")?.remove();
  }
}
