class ChatsController < ApplicationController
  before_action :authenticate_user!

  def index
    @chats = current_user.chats.includes(:messages).order(updated_at: :desc)
  end

  def show
    @chat = Chat.find(params[:id])
    @messages = @chat.messages.includes(:user).order(created_at: :asc)
    @all_chats = Chat.where(user1_id: current_user.id).or(Chat.where(user2_id: current_user.id))
    @all_friends = current_user.friends
    @friend_requests = current_user.received_friend_requests.pending.includes(:sender)
    # 自分宛未読メッセージを既読に変更する
    @chat.messages.where.not(user_id: current_user.id).update_all(read: true)

    @message = Message.new
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
