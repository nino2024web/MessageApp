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
      partial: 'layouts/leftSide/friend_list',
      locals: { all_friends: user.friends }
    )
  end
end
