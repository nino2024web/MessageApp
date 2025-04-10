class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @message = current_user.messages.build(message_params)
    @chat = @message.chat

    if @message.save
      handle_successful_save
    else
      handle_failed_save
    end
  end

  private

  def handle_successful_save
    @saved_message = @message
    @message = Message.new
    respond_to(&:turbo_stream)
  end

  def handle_failed_save
    load_chat_data
    @message = Message.new
    respond_to do |format|
      format.turbo_stream { render_failed_turbo_stream }
      format.html { render 'chats/show', status: :unprocessable_entity }
    end
  end

  def load_chat_data
    @all_chats = Chat.where(user1_id: current_user.id).or(Chat.where(user2_id: current_user.id))
    @all_friends = current_user.friends
    @friend_requests = current_user.received_friend_requests.pending.includes(:sender)
  end

  def render_failed_turbo_stream
    render turbo_stream: turbo_stream.replace(
      'chat-input',
      partial: 'layouts/center/chat_input',
      locals: { chat: @chat, message: @message }
    )
  end

  def message_params
    params.require(:message).permit(:content, :chat_id)
  end
end
