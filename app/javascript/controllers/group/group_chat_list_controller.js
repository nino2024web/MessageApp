// app/javascript/controllers/group/group_chat_list_controller.js
import { Controller } from "@hotwired/stimulus";
import { subscribeToGroupChat } from "channels/group_channel";

export default class extends Controller {
  static values = { chatRoomId: Number, userId: Number };

  connect() {
    this.subscription = subscribeToGroupChat(
      this.chatRoomIdValue,
      this.userIdValue,
      (data) => this.handleData(data)
    );
  }

  handleData(data) {
    if (data.type === "replace") {
      const existing = document.querySelector(
        `#group-chat-item-${data.chat_room_id}`
      );
      if (existing) {
        existing.outerHTML = data.html;
      } else {
        document
          .querySelector("#other-group-chat-list")
          ?.insertAdjacentHTML("beforeend", data.html);
      }
    } else if (data.type === "unread_count") {
      const box = document.querySelector(`#unread-count-${data.chat_room_id}`);
      if (box) box.outerHTML = data.html;
    } else if (data.type === "deleted_by_creator") {
      document.querySelector(`#group-chat-item-${data.chat_room_id}`)?.remove();

      if (Number(this.chatRoomIdValue) === Number(data.chat_room_id)) {
        this.removeGroupChatFromDOM(data.chat_room_id);
        alert(data.message);
        window.location.href = `/group/users/${this.userIdValue}`;
      }
    }
  }

  // header-クリック系
  confirmLeave(e) {
    const groupChatId = e.currentTarget.dataset.groupChatId;
    if (confirm("本当に退会しますか？")) this.leaveGroup(groupChatId);
  }

  confirmDelete(e) {
    const groupChatId = e.currentTarget.dataset.groupChatId;
    if (confirm("本当にグループチャットを削除しますか？"))
      this.leaveGroup(groupChatId);
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
      // ローカルだけで消す（作成者削除・参加者退会どちらもここ）
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

  disconnect() {
    this.subscription?.unsubscribe?.();
  }
}
