class UserGroupChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "user_#{params[:user_id]}_group_chat"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
