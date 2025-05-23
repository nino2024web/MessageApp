class GroupMessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @chat_room = ChatRoom.find(params[:group_message][:chat_room_id])
    @group_message = GroupMessage.new(group_message_params)
    @group_message.user = current_user

    if @group_message.save
      handle_successful_save
    else
      handle_failed_save
    end
  end

  private

  def group_message_params
    params.require(:group_message).permit(:content, :chat_room_id)
  end

  def handle_successful_save
    respond_to do |format|
      format.turbo_stream
      format.html do
        redirect_to group_user_path(current_user, chat_room_id: @chat_room.id)
      end
    end
  end

  def handle_failed_save
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace('group_message_errors', partial: 'shared/errors',
                                                                          locals: { object: @message })
      end
      redirect_to group_user_path(current_user, chat_room_id: @chat_room.id)
    end
  end
end
