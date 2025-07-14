import consumer from "./consumer"

export const subscribeToGroupChat = (chatRoomId, callback) => {
  return consumer.subscriptions.create(
    { channel: "GroupChannel", chat_room_id: chatRoomId },
    {
      connected() {
        console.log(`✅ Connected to GroupChannel ${chatRoomId}`);
      },

      disconnected() {
        console.log(`❌ Disconnected from GroupChannel ${chatRoomId}`);
      },

      received(data) {
        console.log("📥 Message received from GroupChannel");
        callback(data);
      },
    }
  );
};
