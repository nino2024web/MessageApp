class ChatRoom < ApplicationRecord
  has_many :chat_room_users, dependent: :destroy
  has_many :users, through: :chat_room_users
  has_many :group_messages, dependent: :destroy

  validates :name, presence: true, uniqueness: true, length: { maximum: 10 }

  def creator
    users.find_by(id: creator_id)
  end

  # 自分以外の未読メッセージ数
  def unread_count_for(user)
    group_messages
      .where.not(user_id: user.id)
      .left_joins(:group_message_reads)
      .where(group_message_reads: { user_id: nil })
      .count
  end

  # 指定ユーザーに対してメッセージを既読にする
  def mark_messages_as_read_for(user)
    group_messages
      .where.not(user_id: user.id)
      .left_joins(:group_message_reads)
      .where(group_message_reads: { user_id: nil })
      .find_each do |message|
        GroupMessageRead.create(user: user, group_message: message, chat_room: self)
      end
  end
end
