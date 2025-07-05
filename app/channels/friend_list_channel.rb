class FriendListChannel < ApplicationCable::Channel
  def subscribed
    stream_from "friend_list_#{params[:id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
