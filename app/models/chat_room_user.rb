class ChatRoomUser < ApplicationRecord
  belongs_to :user
  belongs_to :chat_room

  # ユーザーが同じグループチャットに参加できないようにする
  validates :user_id, uniqueness: { scope: :chat_room_id }
end
