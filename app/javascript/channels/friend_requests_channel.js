import consumer from "channels/consumer";

const userId = document.body.dataset.currentUserId;

if (userId) {
  consumer.subscriptions.create(
    { channel: "FriendRequestsChannel", id: userId },
    {
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
              }
            });

          //ボタン更新
          if (data.html && data.userId) {
            const target = document.querySelector(
              `#friend-request-btn-${data.userId}`
            );

            if (target) {
              target.outerHTML = data.html;
            }
          }
        }
      },
    }
  );
}
