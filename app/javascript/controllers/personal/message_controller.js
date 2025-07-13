import { Controller } from "@hotwired/stimulus";
import { subscribeToChat } from "../../channels/chat_channel";

export default class extends Controller {
  static targets = ["messages"];
  static values = { chatId: String };

  connect() {
    this.messagesContainer = this.messagesTarget;
    this.scrollToBottom();

    if (!this.hasChatIdValue) {
      console.error("chatId が指定されていない");
      return;
    }

    // 既読メッセージ左右分け
    const currentUserId = document.body.dataset.currentUserId;

    this.messagesContainer.querySelectorAll(".message").forEach((msg) => {
      const userId = msg.dataset.userId;
      if (userId === currentUserId) {
        msg.classList.add("own-message");
      } else {
        msg.classList.add("other-message");
      }
    });

    //ActionCable
    this.subscription = subscribeToChat(this.chatIdValue, (html) => {
      const temp = document.createElement("div");
      temp.innerHTML = html.trim();
      const messageNode = temp.firstElementChild;

      if (messageNode) {
        const userId = messageNode.dataset.userId;
        const currentUserId = document.body.dataset.currentUserId;

        // 既読チェック
        if (userId !== currentUserId) {
          const messageId = messageNode.dataset.id;

          fetch(`/messages/${messageId}/mark_as_read`, {
            method: "POST",
            headers: {
              "X-CSRF-Token": document.querySelector("[name='csrf-token']")
                .content,
            },
          });
        }

        // message左右分け処理
        messageNode.classList.remove("own-message", "other-message");
        if (userId === currentUserId) {
          messageNode.classList.add("own-message");
        } else {
          messageNode.classList.add("other-message");
        }

        this.messagesContainer.appendChild(messageNode);

        requestAnimationFrame(() => {
          this.scrollToBottom();
        });
      }
    });
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
  }

  scrollToBottom() {
    const messages = this.messagesContainer;
    if (messages) {
      messages.scrollTop = messages.scrollHeight;
    }
  }
}
