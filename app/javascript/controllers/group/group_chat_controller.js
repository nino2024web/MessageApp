import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { chatRoomId: Number };

  connect() {
    this.markMessagesAsRead();
    this.scrollToBottom();
  }

  async markMessagesAsRead() {
    const csrfToken = document.querySelector("meta[name='csrf-token']").content;

    try {
      await fetch("/group_messages/mark_as_read", {
        method: "POST",
        headers: {
          "X-CSRF-Token": csrfToken,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ chat_room_id: this.chatRoomIdValue }),
      });
    } catch (error) {
      console.error("既読処理に失敗しました:", error);
    }
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight;
  }
}
