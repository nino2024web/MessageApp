import { Controller } from "@hotwired/stimulus";
import consumer from "../channels/consumer";

export default class extends Controller {
  static targets = ["form", "results"];

  connect() {
    const currentUserId = document.body.dataset.currentUserId;

    this.subscription = consumer.subscriptions.create(
      { channel: "FriendSearchChannel", user_id: currentUserId },
      {
        received: (html) => {
          this.resultsTarget.innerHTML = html;
        },
      }
    );
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
  }

  search(e) {
    e.preventDefault();

    const form = this.formTarget;
    const formData = new FormData(form);

    fetch(form.action, {
      method: form.method,
      headers: {
        "X-CSRF-Token": document.querySelector("[name=csrf-token]").content,
      },
      body: formData,
    })
      .then((response) => {
        if (!response.ok) throw new Error("送信失敗");
      })
      .catch((error) => {
        console.error("フォーム送信エラー::", error);
      });
  }
}
