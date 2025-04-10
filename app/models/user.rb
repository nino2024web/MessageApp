class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :timeoutable

  validates :name, presence: true, uniqueness: { case_sensitive: false, message: '同じ名前が登録されています' }
  validates :email, uniqueness: { case_sensitive: false, message: '同じメールアドレスが登録されています' }

  has_many :friendships, dependent: :destroy
  has_many :friends, through: :friendships

  has_many :chat_users
  has_many :chats, through: :chat_users
  has_many :messages

  has_many :sent_friend_requests, class_name: 'FriendRequest', foreign_key: 'sender_id', dependent: :destroy
  has_many :received_friend_requests, class_name: 'FriendRequest', foreign_key: 'receiver_id', dependent: :destroy

  # blockしたユーザー
  has_many :blocks
  has_many :blocked_users, through: :blocks, source: :blocked_user

  # blockされたユーザー
  has_many :reverse_blocks, class_name: 'Block', foreign_key: :blocked_user_id
  has_many :blockers, through: :reverse_blocks, source: :user

  # 部分一致名前検索
  scope :search_by_name, ->(name) { where('name LIKE ?', "%#{name}%") }

  # メインチャットルーム
  def find_or_create_chat(friend)
    # 既存のチャットルームの有無を確認
    existing_chat = chats.joins(:users).where(users: { id: friend.id }).first

    return existing_chat if existing_chat.present?

    # なければ新しく作成
    Chat.find_or_create_by(user1_id: id, user2_id: friend.id) do |c|
      c.name = "#{name}_#{friend.name}"
    end
  end
end
