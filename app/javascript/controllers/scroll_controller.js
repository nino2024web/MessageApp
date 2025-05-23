import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // connect() {
  //   this.element.scrollIntoView({ behavior: "smooth" });
  // }

  connect() {
    this.scrollIntoView();
  }

  scrollIntoView() {
    setTimeout(() => {
      this.element.scrollIntoView({ behavior: "smooth" })
    }, 10)
  }
}