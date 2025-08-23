class GroupChatsController < ApplicationController
  before_action :authenticate_user!

  def show
    @chat_room = ChatRoom.find(params[:id])
    @group_messages = @chat_room.group_messages.includes(:user)
    @group_message = GroupMessage.new
  end

  def destroy
    chat_room = ChatRoom.find(params[:id])

    if chat_room.creator_id == current_user.id
      # 非削除側ユーザーに通知を送る
      chat_room.users.where.not(id: current_user.id).each do |user|
        ActionCable.server.broadcast(
          "user_#{user.id}_group_chat",
          {
            type: 'deleted_by_creator',
            chat_room_id: chat_room.id,
            message: 'このグループチャットは作成者によって削除されました。'
          }
        )
      end

      # 実データ削除
      ChatRoomUser.where(chat_room_id: chat_room.id).delete_all
      GroupMessage.where(chat_room_id: chat_room.id).delete_all
      GroupMessageRead.where(chat_room_id: chat_room.id).delete_all

      chat_room.destroy
    else

      # 作成者以外 → 中間テーブルから自分を削除(退会)
      membership = ChatRoomUser.find_by(user_id: current_user.id, chat_room_id: chat_room.id)
      membership&.destroy
    end

    head :ok
  end

  def broadcast_updated_chat_item
    chat_room = ChatRoom.find(params[:chat_room_id])

    # グループチャットメンバー一覧HTML
    members_html = render_to_string(
      partial: 'layouts/leftSide/group_chat/participant_list',
      locals: { chat_room: chat_room },
      formats: [:html]
    )

    # 各ユーザーにブロードキャスト
    chat_room.users.each do |user|
      html = render_to_string(
        partial: 'layouts/leftSide/group_chat/group_chat_item',
        locals: { chat_room: chat_room, current_user: user },
        formats: [:html]
      )

      ActionCable.server.broadcast(
        "user_#{user.id}_group_chat",
        {
          type: 'update_members',
          count_html: "#{chat_room.users.count}人",
          members_html: members_html,
          html: html,
          chat_room_id: chat_room.id,
          current: false
        }
      )

      invite_candidates_html = render_to_string(
        partial: 'layouts/leftSide/group_chat/invite_candidates',
        locals: {
          chat_room: chat_room,
          invite_candidates: chat_room.invitable_users(user)
        },
        formats: [:html]
      )

      ActionCable.server.broadcast(
        "user_#{user.id}_group_chat",
        {
          type: 'update_inviteCandidates',
          html: invite_candidates_html
        }
      )
    end

    head :ok
  end
end
