import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["textarea"];

  sendMessage(e) {
    e.preventDefault();
    const form = this.element;
    const textarea = this.textareaTarget;
    const content = textarea.value.trim();

    if (content === "") {
      textarea.placeholder = "空白です。メッセージを入力してください";
      return;
    }

    const formData = new FormData(form);

    fetch(form.action, {
      method: "POST",
      headers: {
        Accept: "text/html",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
      },
      body: formData,
    })
      .then((response) => {
        if (!response.ok) throw new Error("投稿失敗");
        return response.text();
      })
      .then((_html) => {
        form.reset();
        textarea.placeholder = "メッセージを入力してください";
      })
      .catch((error) => {
        console.error("fetchエラー発生:", error);
        textarea.placeholder = "エラー発生しました。再試行してください";
      });
  }

  checkEnter(e) {
    if (e.isComposing) return;
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      this.sendMessage(e);
    }
  }
}
