import { Controller } from "@hotwired/stimulus";
import { createConsumer } from "@rails/actioncable";

export default class extends Controller {
  static values = { userId: Number };

  connect() {
    this.subscription = createConsumer().subscriptions.create(
      { channel: "FriendsChannel", id: this.userIdValue },
      {
        received: (html) => {
          const target = document.getElementById(
            `friend-request-btn-${this.userIdValue}`
          );
          if (target) {
            target.innerHTML = html;
          } else {
            console.warn(
              `❗ DOMが見つかりません: friend-request-btn-${this.userIdValue}`
            );
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

  request(e) {
    e.preventDefault();

    fetch("/friend_requests", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name=csrf-token]").content,
      },
      body: JSON.stringify({ receiver_id: this.userIdValue }),
    })
      .then((response) => {
        if (!response.ok) throw new Error("申請失敗");
      })
      .catch((err) => {
        console.error("エラー：", err);
      });
  }
}
