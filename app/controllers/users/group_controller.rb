module Users
  class GroupController < ApplicationController
    before_action :authenticate_user!
    before_action :set_user

    def show
      load_user_data
      load_group_chat_data if params[:chat_room_id].present?
      @ordered_rooms = sort_chat_rooms
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def load_user_data
      @chat_rooms = @user.chat_rooms.includes(:group_messages)

      # 並び替え処理
      if params[:chat_room_id].present?
        @chat_room = ChatRoom.find_by(id: params[:chat_room_id])
        other_rooms = @chat_rooms.where.not(id: @chat_room.id)
                                 .sort_by { |room| room.group_messages.last&.created_at || Time.at(0) }
                                 .reverse
        @ordered_rooms = [@chat_room] + other_rooms
      else
        @ordered_rooms = @chat_rooms.sort_by { |room| room.group_messages.last&.created_at || Time.at(0) }.reverse
      end

      @ordered_rooms = @ordered_rooms.first(10) # 表示最大10件
      @all_friends = @user.friends.order(:name)
      return unless @chat_room.present?

      @invite_candidates = @user.friends.where.not(id: @chat_room.users.select(:id)).order(:name)
    end

    def load_group_chat_data
      @chat_room = ChatRoom.includes(:users).find_by(id: params[:chat_room_id])
      @group_messages = @chat_room.group_messages.includes(:user).order(:created_at)
      @group_message = GroupMessage.new

      # メンバー表示　最大10人 作成者上位
      creator = @chat_room.users.find_by(id: @chat_room.creator_id)
      others = @chat_room.users.where.not(id: @chat_room.creator_id).order(:name)
      @sorted_members = ([creator] + others).compact.first(10)
    end

    def sort_chat_rooms
      if @chat_room
        @chat_rooms.sort_by do |room|
          if room.id == @chat_room.id
            [0, Time.current]
          else
            last_message_time = room.group_messages.last&.created_at || Time.at(0)
            [1, -last_message_time.to_i]
          end
        end
      else
        @chat_rooms.sort_by do |room|
          last_message_time = room.group_messages.last&.created_at || Time.at(0)
          -last_message_time.to_i
        end
      end
    end
  end
end
