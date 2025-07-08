import consumer from "channels/consumer";

const userId = document.body.dataset.currentUserId;

if (userId) {
  consumer.subscriptions.create(
    { channel: "FriendSearchChannel", id: userId },
    {
      received(data) {
        const container = document.querySelector("#search-results");
        if (container) {
          container.innerHTML = data;
        }
      },
    }
  );
}
