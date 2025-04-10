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

    @message = Message.new
  end

  def create
    user1 = current_user
    # 👈 相手ユーザーのIDを受け取る
    user2 = User.find(params[:user_id])

    # すでにチャットがあるか探す
    @chat = Chat.between(user1, user2)

    # なければ新しく作成
    @chat ||= Chat.create(user1:, user2:)

    redirect_to @chat
  end

  private

  def chat_params
    params.require(:chat).permit(:name)
  end
end
