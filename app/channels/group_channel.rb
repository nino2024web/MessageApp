class GroupChannel < ApplicationCable::Channel
  def subscribed
    chat_room = ChatRoom.find(params[:chat_room_id])
    stream_from "group_chat_#{chat_room.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
