class ChatsController < ApplicationController
  before_action :authenticate_user!

  def show
    @messages = @chat.messages.includes(:user)
    @message = Message.new

    @chat.messages
         .where.not(user_id: current_user.id)
         .where(read: [false, nil])
         .update_all(read: true)
  end

  private

  def set_chat
    @chat = Chat.find(params[:id])
  end
end
