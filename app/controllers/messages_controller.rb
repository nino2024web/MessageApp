class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @message = current_user.messages.build(message_params.merge(read: false))
    @chat = @message.chat

    if @message.save
      rendered_html = render_to_string(
        partial: 'layouts/center/personal_chat/message',
        locals: { message: @message, current_user: @message.user }
      )
      ActionCable.server.broadcast("chat_#{@chat.id}", rendered_html)

      [@chat.user1, @chat.user2].each do |u|
        chat_list_html = render_to_string(
          partial: 'layouts/leftSide/personal_chat/chat_list',
          locals: { all_chats: u.chats.order(updated_at: :desc), current_user: u }
        )
        ActionCable.server.broadcast("chat_list_#{u.id}", chat_list_html)
      end

      FriendsChannel.broadcast_to(
        @chat.other_user(current_user),
        {
          type: 'new_unread_message',
          chat_id: @chat.id,
          unread_count: @chat.unread_count_for(@chat.other_user(current_user))
        }
      )

      head :ok
    else
      head :unprocessable_entity
    end
  end

  def mark_as_read
    message = Message.find(params[:id])
    return unless message.user_id != current_user.id && !message.read

    message.update(read: true)

    head :ok
  end

  private

  def message_params
    params.require(:message).permit(:content, :chat_id)
  end
end
