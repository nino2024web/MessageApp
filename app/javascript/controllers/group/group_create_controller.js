import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];

  async create(e) {
    e.preventDefault();
    const form = e.currentTarget;
    const formData = new FormData(form);
    const csrfToken = document.querySelector("[name='csrf-token']").content;

    try {
      const response = await fetch("/chat_rooms", {
        method: "POST",
        headers: {
          "X-CSRF-Token": csrfToken,
          Accept: "application/json",
        },
        body: formData,
      });

      const data = await response.json();

      if (response.ok && data.success) {
        // 成功時：チャットリストに追加、フォームを初期化、エラー消す
        document
          .getElementById("other-group-chat-list")
          .insertAdjacentHTML("afterbegin", data.chat_html);

        form.reset();

        // フォームも置き換え（errorsなしの新しいChatRoomで描画されたform）
        const wrapper = document.getElementById("group-create-form");
        const newWrapper = document.createElement("div");
        newWrapper.innerHTML = data.form_html;
        wrapper.replaceWith(newWrapper.firstElementChild);
      } else {
        // 失敗時：エラー付きformに置き換え
        this.replaceForm(data.form_html);
      }
    } catch (err) {
      console.warn("グループ作成に失敗しました", err);
    }
  }

  replaceForm(html) {
    const wrapper = document.getElementById("group-create-form");
    if (!wrapper) return;

    const newWrapper = document.createElement("div");
    newWrapper.innerHTML = html;
    wrapper.replaceWith(newWrapper.firstElementChild);
  }

  checkEnter(e) {
    if (e.isComposing) return;
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      this.create(e);
    }
  }
}
