import { Controller } from "@hotwired/stimulus";
import { subscribeToChat } from "../../channels/chat_channel";

export default class extends Controller {
  static targets = ["messages"];
  static values = { chatId: String };

  connect() {
    this.messagesContainer = this.messagesTarget;

    // 強制スクロール初期化
    this.initStickyBottom({ mode: "always", burstMs: 0 });

    if (!this.hasChatIdValue) {
      console.error("chatId が指定されていない");
      return;
    }

    // 既存メッセージの左右振り分け
    const currentUserId = document.body.dataset.currentUserId;
    this.messagesContainer.querySelectorAll(".message").forEach((msg) => {
      const userId = msg.dataset.userId;
      msg.classList.toggle("own-message", userId === currentUserId);
      msg.classList.toggle("other-message", userId !== currentUserId);
    });

    // ActionCable 購読
    this.subscription = subscribeToChat(this.chatIdValue, (html) => {
      const temp = document.createElement("div");
      temp.innerHTML = html.trim();
      const messageNode = temp.firstElementChild;
      if (!messageNode) return;

      const userId = messageNode.dataset.userId;
      const cu = document.body.dataset.currentUserId;

      // 既読
      if (userId !== cu) {
        const messageId = messageNode.dataset.id;
        fetch(`/messages/${messageId}/mark_as_read`, {
          method: "POST",
          headers: {
            "X-CSRF-Token": document.querySelector("[name='csrf-token']")
              .content,
          },
        }).catch(() => {});
      }

      // 左右クラス
      messageNode.classList.remove("own-message", "other-message");
      messageNode.classList.add(
        userId === cu ? "own-message" : "other-message"
      );

      this.messagesContainer.appendChild(messageNode);
      this.bumpStickyBottom();

      messageNode.querySelectorAll("img").forEach((img) => {
        if (!img.complete)
          img.addEventListener("load", () => this.bumpStickyBottom(), {
            once: true,
          });
      });
    });
  }

  disconnect() {
    if (this.subscription) this.subscription.unsubscribe();
    this.teardownStickyBottom();
  }

  //  強制スクロール実装
  initStickyBottom({ mode = "always", burstMs = 0 } = {}) {
    this._forceStick = mode === "always";
    this._burstMs = burstMs;
    this._burstTimer = null;

    // スクロール対象は messagesContainer 固定
    const el = (this.messagesContainer =
      this.messagesContainer || this.messagesTarget);

    // 高さ変化に追従（追加・画像ロード・フォント計測など）
    this._ro = new ResizeObserver(() => {
      if (this._forceStick) this.rafBottom();
    });
    this._ro.observe(el);

    // ノード追加にも即応（挿入→描画後）
    this._mo = new MutationObserver(() => {
      if (this._forceStick) this.rafBottom();
    });
    this._mo.observe(el, { childList: true, subtree: true });

    // 初回も底へ
    this.rafBottom();
  }

  bumpStickyBottom() {
    if (this._burstMs > 0) {
      // バーストモード：新着後だけ強制
      this._forceStick = true;
      clearTimeout(this._burstTimer);
      this._burstTimer = setTimeout(
        () => (this._forceStick = false),
        this._burstMs
      );
    }
    this.rafBottom();
  }

  // “次フレームで”かつ二度かけで確実に底へ
  rafBottom() {
    const el = this.messagesContainer;
    if (!el) return;
    cancelAnimationFrame(this._raf1);
    cancelAnimationFrame(this._raf2);
    this._raf1 = requestAnimationFrame(() => {
      el.scrollTop = el.scrollHeight;
      this._raf2 = requestAnimationFrame(() => {
        el.scrollTop = el.scrollHeight;
      });
    });
  }

  // 本当に動かない時の最終  強制押し付け
  hardBurst(ms = 1000) {
    const el = this.messagesContainer;
    if (!el) return;
    const tick = () => {
      el.scrollTop = el.scrollHeight;
      this._hardRaf = requestAnimationFrame(tick);
    };
    cancelAnimationFrame(this._hardRaf);
    tick();
    clearTimeout(this._hardBurstTimeout);
    this._hardBurstTimeout = setTimeout(
      () => cancelAnimationFrame(this._hardRaf),
      ms
    );
  }

  teardownStickyBottom() {
    this._ro?.disconnect();
    this._mo?.disconnect();
    clearTimeout(this._burstTimer);
    clearTimeout(this._hardBurstTimeout);
    cancelAnimationFrame(this._raf1);
    cancelAnimationFrame(this._raf2);
    cancelAnimationFrame(this._hardRaf);
  }
}
