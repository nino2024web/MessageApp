class GroupMessageRead < ApplicationRecord
  belongs_to :user
  belongs_to :group_message
  belongs_to :chat_room

  validates :user_id, uniqueness: { scope: :group_message_id }
end
