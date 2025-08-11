class GroupMessageRead < ApplicationRecord
  belongs_to :user
  belongs_to :group_message
  belongs_to :chat_room

  # メッセージ削除時、既読も削除
  has_many :group_message_reads, dependent: :destroy

  validates :user_id, uniqueness: { scope: :group_message_id }
end
