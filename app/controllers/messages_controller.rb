class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @chat = Chat.find(params[:chat_id])
    @message = @chat.messages.build(message_params.merge(user: current_user))
    @message.user = current_user
    if @message.save
      redirect_to chat_path(@chat)
    else
      @messages = @chat.messages.includes(:user).order(created_at: :asc)
      render 'chats/show', status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
