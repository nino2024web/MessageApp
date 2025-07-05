class FriendRequestsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "friend_requests_btn_#{params[:id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end

