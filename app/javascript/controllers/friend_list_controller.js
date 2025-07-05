import { Controller } from "@hotwired/stimulus";
import { createConsumer } from "@rails/actioncable";

export default class extends Controller {
  static values = { userId: Number };
  static targets = ["list"];

  connect() {
    console.log("友達一覧の購読を開始：", this.userIdValue);

    this.subscription = createConsumer().subscriptions.create(
      { channel: "FriendListChannel", id: this.userIdValue },
      {
        received: (html) => {
          if (this.hasListTarget) {
            this.listTarget.innerHTML = html;
            console.log("友達一覧をリアルタイム更新");
          } else {
            console.warm("listTargetが見つかりません");
          }
        },
      }
    );
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe();
      console.log("友達一覧の購読を終了");
    }
  }
}
