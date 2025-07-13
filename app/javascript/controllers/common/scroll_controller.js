import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "append"]

  connect() {
    this.scrollToBottomSmooth()
    this.observe()
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }

  scrollToBottomSmooth() {
    const lastMessage = this.appendTarget?.lastElementChild
    if (lastMessage) {
      lastMessage.scrollIntoView({ behavior: "smooth", block: "end" })
    }
  }

  observe() {
    this.observer = new MutationObserver(() => {
      this.scrollToBottomSmooth()
    })

    if (this.hasAppendTarget) {
      this.observer.observe(this.appendTarget, {
        childList: true,
        subtree: false,
      })
    }
  }
}
