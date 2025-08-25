// app/javascript/controllers/group/group_chat_controller.js
import { Controller } from "@hotwired/stimulus";
import consumer from "channels/consumer";

export default class extends Controller {
  static targets = ["messages"];
  static values = { chatRoomId: Number };

  tag = "[GC]";

  connect() {
    if (!this.hasChatRoomIdValue) return;

    this.container = this.messagesTarget;
    const cu = document.body.dataset.currentUserId || "";

    // 既存メッセ左右
    this.container.querySelectorAll(".message").forEach((msg) => {
      const uid = msg.dataset.userId || "";
      msg.classList.toggle("own-message", uid === cu);
      msg.classList.toggle("other-message", uid !== cu);
    });

    // スクロール監視：ユーザーが最下部へ来たら既読ACK
    this._onScroll = () => {
      if (this.isActive() && this.isNearBottom()) {
        this.markAsReadRoomDebounced(0);
      }
    };
    this.container.addEventListener("scroll", this._onScroll, {
      passive: true,
    });

    // タブ復帰・フォーカス復帰：最下部なら既読ACK
    this._onVis = () => {
      if (this.isActive() && this.isNearBottom())
        this.markAsReadRoomDebounced(0);
    };
    this._onFocus = () => {
      if (this.isActive() && this.isNearBottom())
        this.markAsReadRoomDebounced(0);
    };
    document.addEventListener("visibilitychange", this._onVis);
    window.addEventListener("focus", this._onFocus);

    // 離脱直前の取りこぼし対策
    this._onBeforeUnload = () => {
      if (this.isActive() && this.isNearBottom())
        this._markAsReadRoomNow({ keepalive: true });
    };
    window.addEventListener("beforeunload", this._onBeforeUnload);

    // ActionCable 購読
    this.subscription?.unsubscribe?.();
    this.subscription = consumer.subscriptions.create(
      {
        channel: "GroupChatChannel",
        chat_room_id: this.chatRoomIdValue,
        user_id: cu,
      },
      {
        connected: () => {
          // 接続時に一度だけ底へ
          this.jumpToBottom();
          // 画面がアクティブで、かつ最下部に居る場合のみACK
          if (this.isActive() && this.isNearBottom())
            this.markAsReadRoomDebounced(0);
        },
        received: (data) => this.onReceived(data),
      }
    );
  }

  disconnect() {
    this.subscription?.unsubscribe?.();
    this.subscription = null;

    this.container?.removeEventListener("scroll", this._onScroll);
    document.removeEventListener("visibilitychange", this._onVis);
    window.removeEventListener("focus", this._onFocus);
    window.removeEventListener("beforeunload", this._onBeforeUnload);
    this._onScroll = this._onVis = this._onFocus = this._onBeforeUnload = null;

    clearTimeout(this._markTimer);
    cancelAnimationFrame(this._r1);
    cancelAnimationFrame(this._r2);
  }

  // 受信（append → 条件付きでACK → 最下部へ）
  onReceived(data) {
    if (!data || data.type !== "message" || typeof data.html !== "string")
      return;

    // .message
    const t = document.createElement("div");
    t.innerHTML = data.html.trim();
    const node = t.querySelector(".message") || t.firstElementChild;
    if (!node) return;

    const cu = document.body.dataset.currentUserId || "";
    const uid = node.dataset.userId || "";
    node.classList.remove("own-message", "other-message");
    node.classList.add(uid === cu ? "own-message" : "other-message");

    this.container.appendChild(node);

    // 画像遅延（読了後に最下部へ）
    node.querySelectorAll("img").forEach((img) => {
      if (!img.complete)
        img.addEventListener("load", () => this.jumpToBottom(), { once: true });
    });

    // 見えてる＆最下部付近だけ既読ACK
    if (this.isActive() && this.isNearBottom()) {
      this.markAsReadRoomDebounced(120);
    }

    // 既定動作：新着で最下部へ
    this.jumpToBottom();
  }

  // 最下部へ“確実に”移動
  jumpToBottom() {
    const el = this.container;
    if (!el) return;

    const prevInline = el.style.scrollBehavior;
    el.style.scrollBehavior = "auto";

    cancelAnimationFrame(this._r1);
    cancelAnimationFrame(this._r2);
    this._r1 = requestAnimationFrame(() => {
      el.scrollTop = el.scrollHeight;
      this._r2 = requestAnimationFrame(() => {
        el.scrollTop = el.scrollHeight;
        el.style.scrollBehavior = prevInline || "";
      });
    });
  }

  // 既読グループ処理
  markAsReadRoomDebounced(delay = 250) {
    clearTimeout(this._markTimer);
    this._markTimer = setTimeout(() => this._markAsReadRoomNow(), delay);
  }

  // 連打抑制（1秒クールダウン）
  _lastAckAt = 0;
  _markAsReadRoomNow(opts = {}) {
    const now = Date.now();
    if (now - this._lastAckAt < 1000) return;
    this._lastAckAt = now;

    const token =
      document.querySelector("meta[name='csrf-token']")?.content || "";
    fetch("/group_messages/mark_as_read", {
      method: "POST",
      headers: {
        "X-CSRF-Token": token,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({ chat_room_id: this.chatRoomIdValue }),
      credentials: "same-origin",
      keepalive: !!opts.keepalive,
    }).catch(() => {});
  }

  // 補助：状態判定
  isActive() {
    return (
      document.visibilityState === "visible" && (document.hasFocus?.() ?? true)
    );
  }
  isNearBottom(th = 60) {
    const el = this.container;
    if (!el) return false;
    return el.scrollHeight - el.clientHeight - el.scrollTop <= th;
  }
}
