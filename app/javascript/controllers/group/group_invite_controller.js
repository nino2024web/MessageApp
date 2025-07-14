import { Controller } from "@hotwired/stimulus";
import consumer from "../../channels/consumer";

export default class extends Controller {
  static values = { userId: Number };

  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "UserGroupChatChannel", user_id: this.userIdValue },
      {
        received: (data) => this.receive(data),
      }
    );
  }

  disconnect() {
    if (this.subscription) this.subscription.unsubscribe();
  }

  receive(data) {
    if (data.type === "unread_count") {
      const target = document.getElementById(
        `unread-count-group-${data.chat_room_id}`
      );
      if (target) {
        target.outerHTML = data.html;
      }
    }
  }
}
