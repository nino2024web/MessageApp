class ChatRoomsController < ApplicationController
  before_action :authenticate_user!

  def create
    @chat_room = ChatRoom.new(chat_room_params)
    @chat_room.creator_id = current_user.id

    if @chat_room.save
      ChatRoomUser.create(user: current_user, chat_room: @chat_room)
      handle_successful_creation
    else
      handle_failed_creation
    end
  end

  def invite
    @chat_room = ChatRoom.find(params[:id])
    friend = User.find(params[:user_id])

    if current_user.friends.include?(friend)
      ChatRoomUser.find_or_create_by(chat_room: @chat_room, user: friend)

      @invite_candidates = current_user.friends
                                       .where.not(id: @chat_room.users.select(:id))
                                       .order(:name)
      @sorted_members = begin
        creator = @chat_room.users.find_by(id: @chat_room.creator_id)
        others = @chat_room.users.where.not(id: @chat_room.creator_id).order(:name)
        ([creator] + others).compact.first(10)
      end

      @chat_room.users.each do |user|
        Turbo::StreamsChannel.broadcast_replace_to(
          user,
          target: "group-chat-item-#{@chat_room.id}",
          partial: 'layouts/leftSide/group_chat/group_chat_item',
          locals: { chat_room: @chat_room, current_user: user }
        )
      end

      respond_to do |format|
        format.turbo_stream
        format.html do
          redirect_to group_user_path(current_user, chat_room_id: @chat_room.id),
                      notice: "#{friend.name} を招待しました。"
        end
      end
    else
      redirect_to user_path(current_user, chat_room_id: @chat_room.id),
                  alert: 'このユーザーはあなたの友達ではありません。'
    end
  end

  private

  def chat_room_params
    params.require(:chat_room).permit(:name)
  end

  def handle_successful_creation
    respond_to do |format|
      format.turbo_stream { handle_turbo_stream_response }
      format.html { handle_html_response }
    end
  end

  def handle_turbo_stream_response
    render turbo_stream: [
      append_chat_list,
      replace_create_form
    ]
  end

  def append_chat_list
    # 成功時リスト追加
    turbo_stream.append(
      'my-created-group-chat-list',
      partial: 'layouts/leftSide/group_chat/group_chat_item',
      locals: { chat_room: @chat_room }
    )
  end

  def replace_create_form
    # 成功時フォームを空にして再描画
    turbo_stream.replace(
      'group-create-form',
      partial: 'layouts/leftSide/group_chat/group_create_form',
      locals: {
        chat_room: ChatRoom.new,
        success_message: "グループ名「#{@chat_room.name}」を作成しました"
      }
    )
  end

  def handle_html_response
    redirect_to user_path(current_user, chat_room_id: @chat_room.id)
  end

  def handle_failed_creation
    render turbo_stream: turbo_stream.replace(
      'group-create-form',
      partial: 'layouts/leftSide/group_chat/group_create_form',
      locals: { chat_room: @chat_room }
    )
  end
end
