class GroupMessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @group_message = current_user.group_messages.build(group_message_params)
    @chat_room = @group_message.chat_room

    if @group_message.save
      rendered_html = render_to_string(
        partial: 'layouts/center/group_chat/group_message',
        locals: { message: @group_message, current_user: current_user }
      )

      ActionCable.server.broadcast("group_chat_#{@chat_room.id}", {
                                     type: 'message',
                                     chat_room_id: @chat_room.id,
                                     html: rendered_html
                                   })

      # 未読数更新
      @chat_room.users.where.not(id: current_user.id).each do |user|
        GroupMessageRead.find_or_create_by!(
          user: user,
          group_message: @group_message,
          chat_room: @chat_room
        )

        unread_html = render_to_string(
          partial: 'layouts/leftSide/group_chat/unread_count',
          locals: { chat_room: @chat_room, current_user: user }
        )

        ActionCable.server.broadcast(
          "user_#{user.id}_group_chat",
          {
            chat_room_id: @chat_room.id,
            html: unread_html,
            type: 'unread_count'
          }
        )
      end

      # leftSideのチャット項目全体を更新
      group_chat_html = render_to_string(
        partial: 'layouts/leftSide/group_chat/group_chat_item',
        locals: { chat_room: @chat_room, current_user: current_user }
      )

      @chat_room.users.each do |user|
        ActionCable.server.broadcast(
          "user_#{user.id}_group_chat",
          {
            chat_room_id: @chat_room.id,
            html: group_chat_html,
            type: 'replace'
          }
        )
      end

      render plain: rendered_html, content_type: 'text/html'
    else
      render plain: '保存に失敗しました', status: :unprocessable_entity
    end
  end

  def mark_as_read
    chat_room = ChatRoom.find(params[:chat_room_id])

    unread_messages = chat_room.group_messages
                               .where.not(user_id: current_user.id)
                               .left_joins(:group_message_reads)
                               .where(group_message_reads: { user_id: nil })

    unread_messages.find_each do |message|
      GroupMessageRead.create(user: current_user, group_message: message, chat_room: chat_room)
    end

    head :ok
  end

  private

  def group_message_params
    params.require(:group_message).permit(:content, :chat_room_id)
  end
end
