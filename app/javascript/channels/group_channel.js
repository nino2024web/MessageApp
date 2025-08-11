// app/javascript/channels/group_channel.js
import consumer from "./consumer";

// ユーザーごとの購読を管理（購読1本制御用）
const subs = new Map();

export const subscribeToGroupChat = (chatRoomId, userId, callback) => {
  const key = `u:${userId}`;

  // 既に購読が存在すれば解除してから再購読
  if (subs.has(key)) {
    subs.get(key).unsubscribe();
    subs.delete(key);
  }

  const sub = consumer.subscriptions.create(
    { channel: "GroupChannel", chat_room_id: chatRoomId, user_id: userId },
    {
      connected() {},

      disconnected() {},

      received(data) {
        callback(data);
      },
    }
  );

  subs.set(key, sub);
  return sub;
};
