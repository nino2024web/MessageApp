import { Controller } from "@hotwired/stimulus";
import { subscribeToGroupChat } from "channels/group_channel";

export default class extends Controller {
  static values = { chatRoomId: Number };
  static targets = ["messages"];

  connect() {
    this.messagesContainer = this.messagesTarget;
    this.markMessagesAsRead();

    if (!this.hasChatRoomIdValue) {
      console.error("chatRoomIdValue が設定されていません");
      return;
    }

    // 既存メッセージに左右クラス
    const currentUserId = document.body.dataset.currentUserId;
    this.messagesContainer.querySelectorAll(".message").forEach((msg) => {
      const userId = msg.dataset.userId;
      msg.classList.remove("own-message", "other-message");
      msg.classList.add(
        userId === currentUserId ? "own-message" : "other-message"
      );
    });

    // ActionCable購読
    this.subscription = subscribeToGroupChat(this.chatRoomIdValue, (data) => {
      if (data.type === "message" && typeof data.html === "string") {
        const temp = document.createElement("div");
        temp.innerHTML = data.html.trim();
        const messageNode = temp.firstElementChild;

        if (!messageNode) {
          console.warn("受信したHTMLが無効:", data.html);
          return;
        }

        const userId = messageNode.dataset.userId;
        const currentUserId = document.body.dataset.currentUserId;

        messageNode.classList.remove("own-message", "other-message");
        messageNode.classList.add(
          userId === currentUserId ? "own-message" : "other-message"
        );

        this.messagesContainer.appendChild(messageNode);

        // requestAnimationFrameで確実にスクロールさせる
        requestAnimationFrame(() => this.scrollToBottom());
      }
    });

    // 初回スクロール
    requestAnimationFrame(() => {
      this.scrollToBottom();
    });
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
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
    if (this.messagesContainer) {
      this.messagesContainer.scrollTop = this.messagesContainer.scrollHeight;
    }
  }
}
