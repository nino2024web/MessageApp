import consumer from "channels/consumer";

const userId = document.body.dataset.currentUserId;

if (userId) {
  consumer.subscriptions.create(
    { channel: "FriendSearchChannel", id: userId },
    {
      connected() {
        console.log("FriendSearchChannel に接続");
      },

      disconnected() {
        console.log("FriendSearchChannel 切断");
      },

      received(data) {
        console.log("📦 FriendSearchChannel 経由で受信", data);
        const container = document.querySelector("#search-results");
        if (container) {
          container.innerHTML = data;
          console.log("🔄 検索結果をリアルタイムで更新");
        }
      },
    }
  );
} else {
  console.warn(
    "⚠️ userId が取得できませんでした。ログインしていない可能性があります。"
  );
}
