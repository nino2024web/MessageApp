import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["textarea"];

  sendMessage(e) {
    e.preventDefault();
    const form = this.element;

    // 投稿時、空白ならplaceholderを変更
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
        form.reset(); //フォーム初期化
        textarea.placeholder = "メッセージを入力してください";
      })
      .catch((error) => {
        console.error("fetchエラー発生:", error);
        textarea.placeholder = "エラー発生しました。再試行してください";
      });
  }

  checkEnter(e) {
    // IME変換中は無視
    if (e.isComposing) return;

    // エンタキーのみでも送信できる
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      this.sendMessage(e);
    }
  }
}
