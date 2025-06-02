class GroupMessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @chat_room = ChatRoom.find(params[:group_message][:chat_room_id])
    @group_message = build_message

      if @group_message.save
      @ordered_rooms = current_user.chat_rooms
                                   .includes(:group_messages)
                                   .sort_by do |room|
        if room == @chat_room
          [0, Time.current]
        else
          [1, -(room.group_messages.last&.created_at.to_i || 0)]
        end
      end
      handle_successful_save
    else
      handle_failed_save
    end
  end

  private

  def build_message
    GroupMessage.new(group_message_params).tap do |message|
      message.user = current_user
    end
  end

  def group_message_params
    params.require(:group_message).permit(:content, :chat_room_id)
  end

  def handle_successful_save
    @ordered_rooms = current_user.chat_rooms.includes(:group_messages).sort_by do |room|
      last_time = room.group_messages.last&.created_at || Time.at(0)
      room.id == @chat_room.id ? [0, Time.current] : [1, -last_time.to_i]
    end
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to group_user_path(current_user, chat_room_id: @chat_room.id) }
    end
  end

  def handle_failed_save
    respond_to do |format|
      format.turbo_stream { head :unprocessable_entity }

      redirect_to group_user_path(current_user, chat_room_id: @chat_room.id)
    end
  end
end
