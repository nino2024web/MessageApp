import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];

  async create(e) {
    e.preventDefault();
    const form = e.currentTarget;
    const formData = new FormData(form);

    const csrfToken = document.querySelector("[name='csrf-token']").content;

    const response = await fetch("/chat_rooms", {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        Accept: "application/json",
      },
      body: formData,
    });

    const data = await response.json();

    if (response.ok) {
      document
        .getElementById("my-created-group-chat-list")
        .insertAdjacentHTML("beforeend", data.html);
      // フォームをリセット
      form.reset();
      document.getElementById("group-create-error").innerHTML = "";
    } else {
      // バリデーション失敗時、フォームを置き換える
      document.getElementById("group-create-form").outerHTML = data.html;
    }
  }
}
