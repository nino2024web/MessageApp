import { Controller } from "@hotwired/stimulus";
import { createConsumer } from "@rails/actioncable";

export default class extends Controller {
  static values = { userId: Number };
  static targets = ["list"];

  connect() {
    this.subscription = createConsumer().subscriptions.create(
      { channel: "FriendRequestsChannel", id: this.userIdValue },
      {
        received: (html) => {
          this.listTarget.innerHTML = html;
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
