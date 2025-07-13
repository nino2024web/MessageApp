import { Controller } from "@hotwired/stimulus";
import { createConsumer } from "@rails/actioncable";

export default class extends Controller {
  static values = { userId: Number };
  static targets = ["list"];

  connect() {
    this.subscription = createConsumer().subscriptions.create(
      { channel: "ChatListChannel", user_id: this.userIdValue },
      {
        received: (html) => {
          if (this.hasListTarget) {
            this.listTarget.innerHTML = html;
          }
        },
      }
    );
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
  }
}
