class FriendRequestsController < ApplicationController
  before_action :authenticate_user!

  def create
    receiver = User.find(params[:receiver_id])

    # すでに友達 or リクエスト済みなら無視
    if current_user.friends.include?(receiver) ||
       current_user.sent_friend_requests.where(receiver_id: receiver.id, status: 'pending').exists?
      head :conflict and return
    end

    friend_request = current_user.sent_friend_requests.build(receiver:)

    if friend_request.save

      html_for_sender = render_to_string(
        partial: 'layouts/leftSide/personal_chat/request_button',
        locals: { user: receiver, current_user: current_user }
      )

      html_for_receiver = render_to_string(
        partial: 'layouts/leftSide/personal_chat/request_button',
        locals: { user: current_user, current_user: receiver }
      )

      FriendsChannel.broadcast_to("friend_request_btn_#{receiver.id}", html_for_sender)
      FriendsChannel.broadcast_to("friend_request_btn_#{current_user.id}", html_for_receiver)
      head :ok
    else
      render json: { error: '友達申請に失敗しました' }, status: :unprocessable_entity
    end
  end

  def update
    @friend_request = FriendRequest.find(params[:id])
    process_request(@friend_request)

    if params[:status] == 'accepted'
      broadcast_friend_list(@friend_request.sender)
      broadcast_friend_list(@friend_request.receiver)
    end
    broadcast_friend_requests(@friend_request.receiver)
    head :ok
  end

  private

  def process_request(request)
    case params[:status]
    when 'accepted'
      request.update(status: 'accepted')
      create_friendship(request)
    when 'rejected'
      request.update(status: 'rejected')
    end
  end

  def create_friendship(request)
    Friendship.create(user: request.sender, friend: request.receiver)
    Friendship.create(user: request.receiver, friend: request.sender)
  end

  def broadcast_friend_list(user)
    html = render_to_string(
      partial: 'layouts/leftSide/personal_chat/friend_list',
      locals: { all_friends: user.friends }
    )
    ActionCable.server.broadcast("friend_list_#{user.id}", html)
  end

  def broadcast_friend_requests(user)
    html = render_to_string(
      partial: 'layouts/leftSide/personal_chat/friend_requests',
      locals: {
        friend_requests: user.received_friend_requests.pending
                             .where.not(sender_id: user.blocked_users.ids + user.blockers.ids)
      }
    )
    ActionCable.server.broadcast("friend_requests_#{user.id}", html)
  end
end
