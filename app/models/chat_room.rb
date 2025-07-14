class ChatRoom < ApplicationRecord
  has_many :chat_room_users, dependent: :destroy
  has_many :users, through: :chat_room_users
  has_many :group_messages, dependent: :destroy

  validates :name, presence: true, uniqueness: true, length: { maximum: 10 }

  def creator
    users.find_by(id: creator_id)
  end
end
