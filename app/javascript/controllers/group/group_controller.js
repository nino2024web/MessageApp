import { Controller } from "@hotwired/stimulus";
import { subscribeToGroupChat } from "../../channels/group_channel";

export default class extends Controller {
  static targets = ["messages"];
  static values = { chatRoomId: String };

  connect() {
    console.log("GroupController connected");
    this.messagesContainer = this.messagesTarget;
    this.scrollToBottom();

    if (!this.hasChatRoomIdValue) {
      console.error("chatRoomIdが指定されていません");
      return;
    }

    //　既存メッセージに左右クラス
    const currentUserId = document.body.dataset.currentUserId;
    this.messagesContainer.querySelectorAll(".message").forEach((msg) => {　
      const userId = msg.dataset.userId;
      if (userId === currentUserId) {
        msg.classList.add("own-message");
      } else {
        msg.classList.add("other-message");
      }
    });

    // ActionCable
    subscribeToGroupChat(this.chatRoomIdValue, (html) => {
      const temp = document.createElement("div");
      temp.innerHTML = html.trim();
      const messageNode = temp.firstElementChild;

      if (messageNode) {
        const userId = messageNode.dataset.userId;
        const currentUserId = document.body.dataset.currentUserId;

        if (userId === currentUserId) {
          messageNode.classList.add("own-message");
        } else {
          messageNode.classList.add("other-message");
        }

        this.messagesContainer.appendChild(messageNode);
        this.scrollToBottom();
      }
    });
  }

  scrollToBottom() {
    const messages = this.messagesContainer;
    if (messages) {
      messages.scrollTop = messages.scrollHeight;
    }
  }
}
