import consumer from "channels/consumer";

consumer.subscriptions.create("FriendsChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    if (data.type === "chat_list_update") {
      const chatList = document.getElementById("chat-list");
      if (chatList) {
        chatList.innerHTML = data.html;
      }
    }

    if (data.type === "friend_list_update") {
      const container = document.getElementById("friend-list");
      if (container) {
        container.innerHTML = data.html;
      }
    }
  },
});
