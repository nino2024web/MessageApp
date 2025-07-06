import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    id: Number, //　friend_requestID
    blockedUserId: Number, // ブロック対象
    userId: Number, // 友達申請の送信先
  };

  accept() {
    this.sendRequest("accepted");
  }

  reject() {
    this.sendRequest("rejected");
  }

  block(e) {
    fetch("/blocks", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        Accept: "text/html",
      },
      credentials: "same-origin",
      body: JSON.stringify({
        blocked_user_id: this.blockedUserIdValue,
      }),
    })
      .then((response) => {
        if (!response.ok) throw new Error("ブロック失敗");
        const requestItem = this.element.closest(".request-item");
        if (requestItem) requestItem.remove();
      })
      .catch((error) => {
        if (process.env.NODE_ENV === "development") {
          console.error("ブロックエラー:", error);
        }
      });
  }

  request() {
    fetch("/friend_requests", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        Accept: "text/html",
      },
      credentials: "same-origin",
      body: JSON.stringify({
        receiver_id: this.userIdValue,
      }),
    })
      .then((response) => {
        if (!response.ok) throw new Error("申請失敗");
        return response.text();
      })
      .then((html) => {
        const target = document.querySelector(
          `#friend-request-btn-${this.userIdValue}`
        );
        if (target) {
          target.outerHTML = html;
        }
      })
      .catch((error) => {
        if (process.env.NODE_ENV === "development") {
          console.error("申請エラー:", error);
        }
      });
  }

  sendRequest(status) {
    fetch(`/friend_requests/${this.idValue}?status=${status}`, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        Accept: "text/html",
      },
      credentials: "same-origin",
    })
      .then((response) => {
        if (!response.ok) throw new Error("送信失敗");
        return response.text();
      })
      .then((html) => {
        if (status === "accepted") {
          this.element.innerHTML = html;
        } else if (status === "rejected") {
          const item = this.element.closest(".request-item");
          if (item) item.remove();

          const remaining = document.querySelectorAll(".request-item");
          if (remaining.length === 0) {
            const container = document.getElementById("friend-requests");
            if (container) {
              container.innerHTML = `<p class="no-chat-message">友達リクエストはありません。</p>`;
            }
          }
        }
      })
      .catch((error) => {
        if (process.env.NODE_ENV === "development") {
          console.error("リクエストエラー:", error);
        }
      });
  }
}
