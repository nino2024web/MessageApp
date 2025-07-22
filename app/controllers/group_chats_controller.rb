class GroupChatsController < ApplicationController
  before_action :authenticate_user!

  def show
    @chat_room = GroupChat.find(params[:id])
    @group_messages = @chat_room.group_messages.includes(:user)
    @group_message = GroupMessage.new
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
        "user_group_chat_#{user.id}",
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
        "user_group_chat_#{user.id}",
        {
          type: 'update_inviteCandidates',
          html: invite_candidates_html
        }
      )
    end

    head :ok
  end
end
