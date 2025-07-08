import consumer from "channels/consumer";

export const subscribeToChat = (chatId, callback) => {
  const subscription = consumer.subscriptions.create(
    { channel: "ChatChannel", chat_id: chatId },
    {
      received(data) {
        // stimulusに処理返す
        callback(data);
      },
    }
  );
  return subscription;
};
