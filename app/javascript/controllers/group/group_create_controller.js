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

      // JSON形式にてスレポンス返す
      const data = await response.json();

      if (response.ok && data.success) {
        // 成功処理
        document
          .getElementById("other-group-chat-list")
          .insertAdjacentHTML("afterbegin", data.html);
        form.reset();
        const errorBox = document.getElementById("group-create-error");
        if (errorBox) errorBox.textContent = "";
      } else {
        // バリデーション失敗などの正常なエラー（主にブラウザ側422ステータスコード）
        this.replaceForm(data.html);
      }
    } catch (err) {
      // fetch 自体が失敗（サーバーダウン等）
      console.warn("⚠️ グループ作成に失敗しました", err);
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
