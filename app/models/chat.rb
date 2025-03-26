class Chat < ApplicationRecord
  has_many :chat_users
  has_many :users, through: :chat_users
  has_many :messages, dependent: :destroy

  # 最近のメッセージ取得の有無
  def latest_message
    messages.order(created_at: :desc).limit(1).pluck(:content).first || 'メッセージなし'
  end

  # ユーザーの未読メッセージを表示
  def unread_messages_count_for(user)
    messages.where(user:, read: false).count
  end
end
