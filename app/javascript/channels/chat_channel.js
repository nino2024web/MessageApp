import consumer from "channels/consumer";

export const subscribeToChat = (chatId, callback) => {
  return consumer.subscriptions.create(
    { channel: "ChatChannel", chat_id: chatId },
    {
      connected() {
        console.log(`Connected to ChatChannel ${chatId}`);
      },

      disconnected() {
        console.log(`Disconnected from ChatChannel ${chatId}`);
      },

      received(data) {
        console.log("Message received from ActionCable");
        // stimulusに処理返す
        callback(data);
      },
    }
  );
};
