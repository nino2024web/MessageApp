class FriendSearchChannel < ApplicationCable::Channel
  def subscribed
    stream_from "friend_search_#{params[:user_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
