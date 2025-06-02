module Users
  class GroupController < ApplicationController
    before_action :authenticate_user!
    before_action :set_user
    before_action :set_chat_room, if: -> { params[:chat_room_id].present? }

    def show
      load_user_data
      load_group_chat_data if params[:chat_room_id].present?
      @ordered_rooms = sort_chat_rooms
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def set_chat_room
      @chat_room = ChatRoom.includes(:users).find_by(id: params[:chat_room_id])
    end

    def load_user_data
      @chat_rooms = @user.chat_rooms.includes(:group_messages)
      @ordered_rooms = sort_chat_rooms
      @all_friends = @user.friends.order(:name)
      load_invite_candidates if @chat_room
    end

    def load_invite_candidates
      @invite_candidates = @user.friends.where.not(id: @chat_room.users.pluck(:id)).order(:name)
    end

    def load_group_chat_data
      @chat_room = ChatRoom.includes(:users).find_by(id: params[:chat_room_id])
      @group_messages = @chat_room.group_messages.includes(:user).order(:created_at)
      @group_message = GroupMessage.new

      @chat_room.mark_messages_as_read_for(current_user)

      # メンバー表示　最大10人 作成者上位
      creator = @chat_room.users.find_by(id: @chat_room.creator_id)
      others  = @chat_room.users.where.not(id: @chat_room.creator_id).order(:name)
      @sorted_members = ([creator] + others).compact.first(10)
    end

    def sort_chat_rooms
      return sort_rooms_by_last_message unless @chat_room

      sort_rooms_with_current_room
    end

    def sort_rooms_by_last_message
      @chat_rooms.sort_by { |room| -(room.group_messages.last&.created_at.to_i || 0) }
    end

    def sort_rooms_with_current_room
      @chat_rooms.sort_by do |room|
        [room.id == @chat_room.id ? 0 : 1, -(room.group_messages.last&.created_at.to_i || 0)]
      end
    end
  end
end
