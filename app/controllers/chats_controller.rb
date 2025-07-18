class ChatsController < ApplicationController
  #   # 個別チャット
  before_action :authenticate_user!
  before_action :set_chat

  def show
    @messages = @chat.messages.includes(:user)
    @message = Message.new

    @chat.messages
         .where.not(user_id: current_user.id)
         .where(read: [false, nil])
         .update_all(read: true)

    FriendsChannel.broadcast_to(
      @chat.other_user(current_user),
      {
        type: 'read_update',
        chat_id: @chat.id,
        user_id: current_user.id
      }
    )
  end

  private

  def set_chat
    @chat = Chat.find(params[:id])
  end
end
