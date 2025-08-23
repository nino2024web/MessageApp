import consumer from "channels/consumer";

// 部屋ごとのメッセージ本文（センター）用ストリーム
export const subscribeRoomStream = (chatRoomId, onReceive = () => {}) =>
  consumer.subscriptions.create(
    { channel: "GroupChatChannel", chat_room_id: chatRoomId },
    {
      connected() {},
      disconnected() {},
      received(data) {
        if (typeof onReceive === "function") onReceive(data);
      },
    }
  );
