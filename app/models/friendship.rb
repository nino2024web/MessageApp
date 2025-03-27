class Friendship < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: 'User'

  after_create_commit -> { broadcast_update }
  after_destroy_commit -> { broadcast_update }

  private

  def broadcast_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "friend_list_#{user.id}",
      target: 'friend-list',
      partial: 'users/friend_list',
      locals: { friends: user.friends }
    )
  end

  # scope :recent_interactions, -> { order(last_interaction_at: :desc) }
  # validates :user_id, uniqueness: { scope: :friend_id, message: 'すでに友達です' } # 二重登録防止
end
