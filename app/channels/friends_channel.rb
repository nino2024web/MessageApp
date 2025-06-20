class FriendsChannel < ApplicationCable::Channel
  def subscribed
    stream_for "friend_request_btn_#{params[:id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
