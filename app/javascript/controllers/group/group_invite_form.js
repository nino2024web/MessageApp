import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { chatRoomId: Number }

  async submit(event) {
    event.preventDefault()
    const form = event.currentTarget
    const formData = new FormData(form)
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    try {
      const response = await fetch(`/chat_rooms/${this.chatRoomIdValue}/invite`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": csrfToken,
          Accept: "application/json"
        },
        body: formData
      })

      const data = await response.json()

      if (response.ok && data.success) {
        form.reset()
        this.showError("")
      } else {
        this.showError(data.error || "招待に失敗しました")
      }
    } catch (e) {
      this.showError("ネットワークエラーが発生しました")
      console.error(e)
    }
  }

  showError(message) {
    const errorBox = document.getElementById("invite-error")
    if (errorBox) {
      errorBox.textContent = message
    }
  }
}
