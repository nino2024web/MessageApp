class ChatRoomsController < ApplicationController
  before_action :authenticate_user!

  def create
    @chat_room = ChatRoom.new(chat_room_params)
    @chat_room.creator_id = current_user.id

    if @chat_room.save
      ChatRoomUser.create(user: current_user, chat_room: @chat_room)

      chat_item_html = render_to_string(
        partial: 'layouts/leftSide/group_chat/group_chat_item',
        locals: { chat_room: @chat_room },
        formats: [:html]
      )

      clean_room = ChatRoom.new
      form_html = render_to_string(
        partial: 'layouts/leftSide/group_chat/group_create_form',
        locals: { chat_room: clean_room },
        formats: [:html]
      )

      render json: {
        success: true,
        chat_html: chat_item_html,
        form_html: form_html,
        chat_room_id: @chat_room.id
      }

    else
      form_html = render_to_string(
        partial: 'layouts/leftSide/group_chat/group_create_form',
        locals: { chat_room: @chat_room },
        formats: [:html]
      )

      render json: {
        success: false,
        form_html: form_html
      }, status: :unprocessable_entity

    end
  end

  def invite
    @chat_room = ChatRoom.find(params[:id])
    friend = User.find(params[:user_id])

    if current_user.friends.include?(friend)
      ChatRoomUser.find_or_create_by(chat_room: @chat_room, user: friend)

      # 招待されたユーザー向けHTML
      begin
        html = render_to_string(
          partial: 'layouts/leftSide/group_chat/group_chat_item',
          formats: [:html],
          locals: { chat_room: @chat_room, current_user: friend }
        )

        ActionCable.server.broadcast(
          "user_#{friend.id}_group_chat",
          { html: html, chat_room_id: @chat_room.id }
        )

        render json: { success: true }
      rescue StandardError => e
        Rails.logger.error("❌ 招待ビューのrender_to_stringでエラー: #{e.message}")
        render json: { success: false, error: '招待の描画中にエラーが発生しました。' }, status: :internal_server_error
      end
    else
      render json: {
        success: false, error: 'このユーザーはあなたの友達ではありません。'
      }, status: :unprocessable_entity
    end
  end

  private

  def chat_room_params
    params.require(:chat_room).permit(:name)
  end
end
