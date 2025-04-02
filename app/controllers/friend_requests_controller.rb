class FriendRequestsController < ApplicationController
  before_action :authenticate_user!

  def create
    receiver = User.find(params[:receiver_id])

    # すでに友達 or リクエスト済みなら無視
    if current_user.friends.include?(receiver) || current_user.sent_friend_requests.exists?(receiver_id: receiver.id)
      head :conflict and return
    end

    friend_request = current_user.sent_friend_requests.build(receiver:)

    if friend_request.save
      render turbo_stream: turbo_stream.replace(
        "friend-request-btn-#{receiver.id}",
        partial: 'layouts/leftSide/request_button', locals: { user: receiver }
      )
    else
      render json: { error: '友達申請に失敗しました' }, status: :unprocessable_entity
    end
  end

  def update
    request = FriendRequest.find(params[:id])

    case params[:status]
    when 'accepted'
      request.update(status: 'accepted')
      Friendship.create(user: request.sender, friend: request.receiver)
      Friendship.create(user: request.receiver, friend: request.sender)

    when 'rejected'
      request.update(status: 'rejected')
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to request.referer || users_path }
    end
  end
end
