import { Controller } from "@hotwired/stimulus";
import consumer from "../channels/consumer";

export default class extends Controller {
  static targets = ["form", "results"];

  connect() {
    const currentUserId = document.body.dataset.currentUserId;

    this.subscription = consumer.subscriptions.create(
      { channel: "SearchResultsChannel", id: currentUserId },
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
    const params = Object.fromEntries(formData.entries());

    fetch(form.action, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": document.querySelector("[name=csrf-token]").content,
      },
      credentials: "same-origin",
      body: JSON.stringify(params),
    }).then((response) => {
      if (!response.ok) throw new Error("送信失敗");
    });
  }
}
