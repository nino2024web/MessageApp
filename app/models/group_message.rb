class GroupMessage < ApplicationRecord
  belongs_to :user
  belongs_to :chat_room
  has_many :group_message_reads, dependent: :destroy

  validates :content, presence: true

  after_create_commit do
    broadcast_append_to(
      "group_chat_#{chat_room_id}",
      target: 'group-messages',
      partial: 'layouts/center/group_chat/group_message',
      locals: { message: self, current_user: user }
    )
  end
end
