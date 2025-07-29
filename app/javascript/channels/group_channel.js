import consumer from "./consumer";

export const subscribeToGroupChat = (chatRoomId, callback) => {
  return consumer.subscriptions.create(
    { channel: "GroupChannel", chat_room_id: chatRoomId },
    {
      connected() {},

      disconnected() {},

      received(data) {
        callback(data);
      },
    }
  );
};
