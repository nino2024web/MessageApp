class GroupChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "group_chat_#{params[:chat_room_id]}"
    stream_from "group_chat_#{params[:user_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
