class FriendRequest < ApplicationRecord
  belongs_to :sender, class_name: 'User'
  belongs_to :receiver, class_name: 'User'

  scope :pending, -> { where(status: 'pending') }

  def accepted?
    status == 'accepted'
  end

  after_create_commit do
    broadcast_replace_to(
      "friend_requests_#{receiver.id}",
      target: 'friend-requests',
      partial: 'layouts/leftSide/personal_chat/friend_requests',
      locals: { friend_requests: receiver.received_friend_requests.pending }
    )
  end

  after_update_commit do
    if accepted?
      [sender, receiver].each do |user|
        broadcast_replace_to(
          "friend_list_#{user.id}",
          target: 'friend-list',
          partial: 'layouts/leftSide/personal_chat/friend_list',
          locals: { all_friends: user.friends }
        )
      end
    end
  end

  private

  def broadcast_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "friend_requests_#{receiver.id}",
      target: 'friend-requests',
      partial: 'layouts/leftSide/personal_chat/friend_requests',
      locals: {
        friend_requests: receiver.received_friend_requests.where(status: 'pending')
      }
    )
  end
end
