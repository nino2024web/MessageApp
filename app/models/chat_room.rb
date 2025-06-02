class ChatRoom < ApplicationRecord
  has_many :chat_room_users, dependent: :destroy
  has_many :users, through: :chat_room_users
  has_many :group_messages, dependent: :destroy

  validates :name, presence: true, uniqueness: true, length: { maximum: 10 }

  def creator
    users.find_by(id: creator_id)
  end

  # 全メッセージを「既読」にマーク（自分以外が投稿した分）
  def mark_messages_as_read_for(user)
    group_messages
      .where.not(user_id: user.id)
      .where(read: [false, nil])
      .update_all(read: true)
  end

  # 自分以外の「未読」メッセージの数
  def unread_count_for(user)
    group_messages
      .where.not(user_id: user.id)
      .left_joins(:group_message_reads)
      .where(group_message_reads: { user_id: nil })
      .count
  end
end
