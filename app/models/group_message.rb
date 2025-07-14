class GroupMessage < ApplicationRecord
  belongs_to :user
  belongs_to :chat_room
  has_many :group_message_reads, dependent: :destroy

  # 投稿文字数最大800文字
  validates :content, presence: true, length: { maximum: 800 }
end
