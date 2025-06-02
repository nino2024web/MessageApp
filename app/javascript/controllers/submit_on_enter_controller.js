import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "form"];

  sendOnEnter(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault();
      this.formTarget.requestSubmit();
    }
  }
}
