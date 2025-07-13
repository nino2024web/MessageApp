class Message < ApplicationRecord
  belongs_to :user
  belongs_to :chat

  after_create_commit -> { chat.touch(:updated_at) } # メッセージが送られたらチャットの更新日時を変更

  # 投稿文字数最大800文字
  validates :content, presence: true, length: { maximum: 800 }
end
