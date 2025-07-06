import consumer from "channels/consumer";

const userId = document.body.dataset.currentUserId;

if (userId) {
  consumer.subscriptions.create(
    { channel: "FriendRequestsChannel", id: userId },
    {
      connected() {
        if (process.env.NODE_ENV === "development") {
          console.log(
            `Subscribed to FriendRequestsChannel for user ${userId}`
          );
        }
      },
      disconnected() {
        if (process.env.NODE_ENV === "development") {
          console.log(
            `Unsubscribed from FriendRequestsChannel for user ${userId}`
          );
        }
      },

      received(data) {
        if (data.action === "reload_requests") {
          fetch("/friend_requests", {
            headers: { Accept: "text/html" },
          })
            .then((res) => res.text())
            .then((html) => {
              const container = document.querySelector("#friend-requests");
              if (container) {
                container.innerHTML = html;
              } else if (process.env.NODE_ENV === "development") {
                console.warn("#friend-requests が見つかりません");
              }
            });

          //ボタン更新
          if (data.html && data.userId) {
            const target = document.querySelector(
              `#friend-request-btn-${data.userId}`
            );

            if (target) {
              target.outerHTML = data.html;
            } else if (process.env.NODE_ENV === "development") {
              console.warn("request_button の DOM が見つかりません");
            }
          }
        }
      },
    }
  );
}
