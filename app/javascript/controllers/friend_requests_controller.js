import { Controller } from "@hotwired/stimulus";
import { createConsumer } from "@rails/actioncable";

export default class extends Controller {
  static values = { userId: Number };
  static targets = ["list"];

  connect() {
    console.log("subscribing:", this.userIdValue);
    this.subscription = createConsumer().subscriptions.create(
      { channel: "FriendRequestsChannel", id: this.userIdValue },
      {
        received: (html) => {
          this.listTarget.innerHTML = html;
          console.log("📦 受信したHTML:", html);
          console.log("リクエスト更新");
        },
      }
    );
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe();
      console.log("リクエスト解除");
    }
  }
}
