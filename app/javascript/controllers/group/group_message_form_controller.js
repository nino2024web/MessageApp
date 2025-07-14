import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  sendMessage(e) {
    e.preventDefault();
    const form = this.element;
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
      })
      .catch((error) => {
        console.error("fetchエラー発生:", error);
        alert("メッセージの送信に失敗しました。");
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
