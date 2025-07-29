import consumer from "channels/consumer";

const element = document.getElementById("group-messages");

if (element) {
  const chatRoomId = element.dataset.groupChatRoomId;

  consumer.subscriptions.create(
    { channel: "GroupChatChannel", chat_room_id: chatRoomId },
    {
      connected() {},

      received(data) {
        callback(data);
      },
    }
  );
}
