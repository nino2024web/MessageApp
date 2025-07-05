import consumer from "channels/consumer";

const userId = document.body.dataset.currentUserId;

if (userId) {
  consumer.subscriptions.create(
    { channel: "FriendRequestsChannel", id: userId },
    {
      connected() {
        console.log(`Subscribed to FriendRequestsChannel for user ${userId}`);
      },

      disconnected() {
        console.log(
          `Unsubscribed from FriendRequestsChannel for user ${userId}`
        );
      },

      received(data) {
        console.log("📦 received:", data);

        if (data.action === "reload_requests") {
          fetch("/friend_requests", {
            headers: { Accept: "text/html" },
          })
            .then((res) => res.text())
            .then((html) => {
              const container = document.querySelector("#friend-requests");
              if (container) {
                container.innerHTML = html;
                console.log("友達リクエスト一覧再描画");
              } else {
                console.warn("⚠ #friend-requests が見つかりません");
              }
            });

          //ボタン更新
          if (data.html && data.userId) {
            const target = document.querySelector(
              `#friend-request-btn-${data.userId}`
            );

            if (target) {
              target.outerHTML = data.html;
              console.log("request_button を承認中に更新");
            } else {
              console.warn("⚠ request_button の DOM が見つかりません");
            }
          }
        }
      },
    }
  );
}
