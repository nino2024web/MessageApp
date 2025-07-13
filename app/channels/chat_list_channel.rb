class ChatListChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_list_#{params[:user_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
