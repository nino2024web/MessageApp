import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { chatRoomId: Number };

  connect() {}

  async submit(event) {
    event.preventDefault();
    const form = event.currentTarget;
    const formData = new FormData(form);
    const csrfToken = document.querySelector(
      "meta[name='csrf-token']"
    )?.content;

    try {
      const response = await fetch(
        `/chat_rooms/${this.chatRoomIdValue}/invite`,
        {
          method: "POST",
          headers: {
            "X-CSRF-Token": csrfToken,
            Accept: "application/json",
          },
          body: formData,
        }
      );

      const text = await response.text();
      try {
        const data = JSON.parse(text);

        if (response.ok && data.success) {
          form.reset();
          this.showError("");
          await fetch("/group_chats/broadcast_updated_chat_item", {
            method: "POST",
            headers: {
              "X-CSRF-Token": csrfToken,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({ chat_room_id: this.chatRoomIdValue }),
          });
        } else {
          this.showError(data.error || "招待に失敗しました");
        }
      } catch (jsonError) {
        console.error("JSONパース失敗:", text);
        this.showError("予期しないレスポンス形式が返されました");
      }
    } catch (e) {
      this.showError("ネットワークエラーが発生しました");
      console.error(e);
    }
  }

  showError(message) {
    const errorBox = document.getElementById("invite-error");
    if (errorBox) {
      errorBox.textContent = message;
    }
  }
}
