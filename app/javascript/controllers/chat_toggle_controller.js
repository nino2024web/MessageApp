import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["privateSection", "groupSection"];

  showPrivate() {
    this.privateSectionTarget.style.display = "block";
    this.groupSectionTarget.style.display = "none";
  }

  showGroup() {
    this.privateSectionTarget.style.display = "none";
    this.groupSectionTarget.style.display = "block";
  }
}
