class ChatsController < ApplicationController
  before_action :authenticate_user!

  def index
    @chats = current_user.chats.includes(:messages).order(updated_at: :desc)
  end

  def show
    @chat = Chat.find(params[:id])
    @messages = @chat.messages.includes(:user).order(created_at: :asc)
  end

  def create
    @chat = Chat.new(chat_params)
    if @chat.save
      redirect_to @chat
    else
      render :new
    end
  end

  private

  def chat_params
    params.require(:chat).permit(:name)
  end
end
