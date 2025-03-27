class FriendRequest < ApplicationRecord
  belongs_to :sender, class_name: 'User'
  belongs_to :receiver, class_name: 'User'

  after_create_commit -> { broadcast_update }
  after_update_commit -> { broadcast_update }

  private

  def broadcast_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "friend_requests_#{receiver.id}",
      target: 'friend-requests',
      partial: 'layouts/leftSide/friend_requests',
      locals: {
        friend_requests: receiver.received_friend_requests.where(status: 'pending')
      }
    )
  end
end
