import { Controller } from "@hotwired/stimulus";
import { subscribeToGroupChat } from "../../channels/group_channel";

export default class extends Controller {
  static values = { chatRoomId: Number };

  connect() {
    this.subscription = subscribeToGroupChat(this.chatRoomIdValue, (data) => {
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
        const countBox = document.querySelector(
          `#unread-count-${data.chat_room_id}`
        );
        if (countBox) {
          countBox.outerHTML = data.html;
        }
      }
    });
  }

  disconnect() {
    if (this.subscription) this.subscription.unsubscribe();
  }
}
