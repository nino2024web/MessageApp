import { Controller } from "@hotwired/stimulus";
import { createConsumer } from "@rails/actioncable";

export default class extends Controller {
  static values = { userId: Number };
  static targets = ["list"];

  connect() {
    this.subscription = createConsumer().subscriptions.create(
      { channel: "FriendListChannel", id: this.userIdValue },
      {
        received: (html) => {
          if (this.hasListTarget) {
            this.listTarget.innerHTML = html;
            this.sortFriendList();
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

  sortFriendList() {
    const items = Array.from(this.listTarget.querySelectorAll(".friend-item"));

    items.sort((a, b) => {
      const nameA = a.querySelector("span").textContent;
      const nameB = b.querySelector("span").textContent;

      const numA = parseInt(nameA.match(/\d+/)?.[0] || 0, 10);
      const numB = parseInt(nameB.match(/\d+/)?.[0] || 0, 10);

      return numA - numB;
    });

    items.forEach((item) => this.listTarget.appendChild(item));
  }
}
