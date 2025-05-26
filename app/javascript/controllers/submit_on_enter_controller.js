import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "form"];
  connect() {
    this.inputTarget.addEventListener("keydown", (e) => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        this.formTarget.requestSubmit();
      }
    });
  }
}
