class ChatRoom < ApplicationRecord
  has_many :chat_room_users, dependent: :destroy
  has_many :users, through: :chat_room_users
  has_many :group_messages, dependent: :destroy

  validates :name, presence: true, uniqueness: true, length: { maximum: 10 }

  def creator
    users.first
  end

  def mark_messages_as_read_for(user)
    group_messages.each do |message|
      GroupMessageRead.find_or_create_by(user: user, group_message: message)
    end
  end

  def unread_count_for(user)
    group_messages
      .left_outer_joins(:group_message_reads)
      .where(group_message_reads: { id: nil })
      .where.not(user_id: user.id)
      .distinct
      .count
  end
end
