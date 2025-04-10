class Chat < ApplicationRecord
  has_many :chat_users
  has_many :users, through: :chat_users
  has_many :messages, dependent: :destroy

  belongs_to :user1, class_name: 'User'
  belongs_to :user2, class_name: 'User'

  # 最近のメッセージ取得の有無
  def latest_message
    messages.order(created_at: :desc).limit(1).pluck(:content).first
  end

  def self.between(user_a, user_b)
    where(user1: user_a, user2: user_b)
      .or(where(user1: user_b, user2: user_a))
      .first
  end

  def other_user(current_user)
    user1 == current_user ? user2 : user1
  end
end
