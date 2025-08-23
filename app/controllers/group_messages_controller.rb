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
      @chat_room.users.find_each do |user|
        item_html = render_to_string(
          partial: 'layouts/leftSide/group_chat/group_chat_item',
          locals: { chat_room: @chat_room, current_user: user }
        )

        ActionCable.server.broadcast(
          "user_#{user.id}_group_chat",
          {
            type: 'replace',
            chat_room_id: @chat_room.id,
            html: item_html
          }
        )

        # leftSideのチャット項目全体を更新
        ActionCable.server.broadcast(
          "user_#{user.id}_group_chat",
          {
            type: 'reorder',
            chat_room_id: @chat_room.id
          }
        )
      end

      render plain: rendered_html, content_type: 'text/html'
    else
      render plain: '保存に失敗しました', status: :unprocessable_entity
    end
  end

  def mark_as_read
    chat_room_id = params[:chat_room_id].to_i
    return head :bad_request if chat_room_id <= 0

    return head :forbidden unless ChatRoomUser.exists?(
      user_id: current_user.id, chat_room_id: chat_room_id
    )

    unread_ids = GroupMessage
                 .where(chat_room_id: chat_room_id)
                 .where.not(user_id: current_user.id)
                 .where.not(
                   id: GroupMessageRead.where(user_id: current_user.id, chat_room_id: chat_room_id)
                                       .select(:group_message_id)
                 ).pluck(:id)

    if unread_ids.any?
      rows = unread_ids.map do |mid|
        { user_id: current_user.id, chat_room_id: chat_room_id, group_message_id: mid,
          created_at: Time.current, updated_at: Time.current }
      end
      GroupMessageRead.insert_all(rows)
    end

    item_html = render_to_string(
      partial: 'layouts/leftSide/group_chat/group_chat_item',
      locals: { chat_room: ChatRoom.find(chat_room_id), current_user: current_user }
    )
    ActionCable.server.broadcast(
      "user_#{current_user.id}_group_chat",
      { type: 'replace', chat_room_id: chat_room_id, html: item_html }
    )

    head :ok
  end

  private

  def group_message_params
    params.require(:group_message).permit(:content, :chat_room_id)
  end
end
