class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @message = current_user.messages.build(message_params)

    render plain: 'チャットが見つかりません', status: :unprocessable_entity and return if @message.chat.nil?

    @chat = @message.chat
    @messages = @chat.messages.includes(:user).order(:created_at)

    if @message.save
      @saved_message = @message 
      handle_successful_save
    else
      @all_chats = Chat.where(user1_id: current_user.id).or(Chat.where(user2_id: current_user.id))
      @all_friends = current_user.friends
      @friend_requests = current_user.received_friend_requests.pending.includes(:sender)
      @message = Message.new
      render 'chats/show', status: :unprocessable_entity
    end
  end

  private

  def handle_successful_save
    @message = Message.new
    respond_to(&:turbo_stream)
  end

  def message_params
    params.require(:message).permit(:content, :chat_id)
  end
end
