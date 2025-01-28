class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :timeoutable

  validates :name, presence: true, uniqueness: { case_sensitive: false, message: '同じ名前が登録されています' }
  validates :email, uniqueness: { case_sensitive: false, message: '同じメールアドレスが登録されています' }

  has_many :friends

  # 最近の友達を取得するメソッド
  def recent_friends
    friends.order('last_interaction_at DESC').limit(5)
  end

  # 全友達リストを取得するメソッド
  def all_friends
    friends
  end
end
