class GroupChatsController < ApplicationController
  before_action :authenticate_user!

  def show
    @chat_room = GroupChat.find(params[:id])
    @group_messages = @chat_room.group_messages.includes(:user)
    @group_message = GroupMessage.new
  end
end
