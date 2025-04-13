// Connects to data-controller="friend-request"

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  remove(event) {
    const listItem = this.element.closest("li.request-item");
    if (listItem) listItem.remove();
  }
}
