class UserGroupChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "user_group_chat_#{current_user.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
