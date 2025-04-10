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
      render turbo_stream: turbo_stream.replace(
        "friend-request-btn-#{receiver.id}",
        partial: 'layouts/leftSide/request_button',
        locals: { user: receiver }
      )
    else
      render json: { error: '友達申請に失敗しました' }, status: :unprocessable_entity
    end

    @friend_requests = current_user.received_friend_requests
                                   .pending
                                   .includes(:sender)
                                   .where.not(sender: current_user.blocked_users + current_user.blockers)
  end

  def update
    friend_request = FriendRequest.find(params[:id])
    process_request(friend_request)
    update_friend_requests
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to request.referer || user_path(current_user) }
    end
  end

  private

  def process_request(request)
    case params[:status]
    when 'accepted'
      accept_request(request)
    when 'rejected'
      request.update(status: 'rejected')
    end
  end

  def accept_request(request)
    request.update(status: 'accepted')
    create_friendship(request)
  end

  def create_friendship(request)
    Friendship.create(user: request.sender, friend: request.receiver)
    Friendship.create(user: request.receiver, friend: request.sender)
  end

  def update_friend_requests
    @friend_requests = current_user.received_friend_requests
                                   .pending
                                   .includes(:sender)
                                   .where.not(sender: current_user.blocked_users + current_user.blockers)
  end
end
