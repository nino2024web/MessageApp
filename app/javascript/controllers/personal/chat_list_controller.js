import { Controller } from "@hotwired/stimulus";
import { createConsumer } from "@rails/actioncable";

export default class extends Controller {
  static values = { userId: Number };
  static targets = ["list"];

  connect() {
    this.subscription = createConsumer().subscriptions.create(
      { channel: "ChatListChannel", user_id: this.userIdValue },
      {
        received: (payload) => {
          if (!this.hasListTarget) return;

          // 文字列 or html 両対応
          const html = typeof payload === "string" ? payload : payload?.html;
          if (!html) return;

          this.listTarget.innerHTML = html;

          // いま表示中の chat_id の未読だけ消す
          const id = new URLSearchParams(location.search).get("chat_id");
          if (id) {
            const wrap = this.listTarget.querySelector(
              `#unread-count-personal-${CSS.escape(id)}`
            );
            if (wrap) wrap.innerHTML = "";
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
