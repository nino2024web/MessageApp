module Users
  class GroupController < ApplicationController
    before_action :authenticate_user!
    before_action :set_user
    before_action :authorize_user!
    before_action :set_chat_room, if: -> { params[:chat_room_id].present? }

    def show
      preload_base_lists
      if @chat_room
        load_room_context(@chat_room)
        mark_room_as_read!(@chat_room, current_user) # ここで一括既読
        refresh_left_list_for!(current_user)
      end
      @ordered_rooms = sort_rooms(@chat_room&.id)
    end

    private

    # --------- guards ---------
    def set_user
      @user = User.find(params[:id])
    end

    def authorize_user!
      head :forbidden unless @user.id == current_user.id
    end

    def set_chat_room
      @chat_room = ChatRoom.includes(:users).find_by(id: params[:chat_room_id])
    end

    # --------- preload (左カラム土台) ---------
    # メッセージ本文はここで読まない。最新時刻/プレビューは別クエリ。
    def preload_base_lists
      @chat_rooms  = @user.chat_rooms.includes(:users)
      @all_friends = @user.friends.order(:name)

      # 各部屋の最新活動時刻
      @latest_map = GroupMessage
                    .where(chat_room_id: @chat_rooms.select(:id))
                    .group(:chat_room_id)
                    .maximum(:created_at)

      # 各部屋の最新メッセージ本文（SQLite対応：MAX(created_at)サブクエリJOIN）
      @preview_map = {}
      ids = @chat_rooms.map(&:id)
      return if ids.empty?

      sub = GroupMessage
            .select('chat_room_id, MAX(created_at) AS max_created_at')
            .where(chat_room_id: ids)
            .group(:chat_room_id)

      rows = GroupMessage
             .select('group_messages.chat_room_id, group_messages.content, group_messages.created_at')
             .joins("INNER JOIN (#{sub.to_sql}) latest "\
                      'ON latest.chat_room_id = group_messages.chat_room_id '\
                      'AND latest.max_created_at = group_messages.created_at')
             .where(chat_room_id: ids)

      rows.each { |m| @preview_map[m.chat_room_id] = m.content }
    end

    # --------- 中央カラム文脈 ---------
    def load_room_context(room)
      @group_messages    = room.group_messages.includes(:user).order(:created_at)
      @group_message     = GroupMessage.new
      @invite_candidates = @user.friends.where.not(id: room.users.select(:id)).order(:name)

      members = room.users.to_a
      # 作成者を先頭、その後は名前で安定ソートし最大10人表示
      @sorted_members = members.sort_by { |u| [u.id == room.creator_id ? 0 : 1, u.name] }.first(10)
    end

    # --------- 既読をDB側一発挿入（SQLite/PG両対応） ---------
    def mark_room_as_read!(room, user)
      joined_at = joined_at_for(user, room)

      now = ActiveRecord::Base.connection.quote(Time.current)
      uid = user.id.to_i
      rid = room.id.to_i
      cond_joined = joined_at ? ActiveRecord::Base.connection.quote(joined_at) : nil

      adapter = ActiveRecord::Base.connection.adapter_name

      insert_head =
        if adapter =~ /SQLite/i
          'INSERT OR IGNORE INTO group_message_reads (user_id, chat_room_id, group_message_id, created_at, updated_at)'
        else
          'INSERT INTO group_message_reads (user_id, chat_room_id, group_message_id, created_at, updated_at)'
        end

      on_conflict =
        if adapter =~ /PostgreSQL/i
          'ON CONFLICT (user_id, group_message_id) DO NOTHING'
        else
          ''
        end

      sql = <<~SQL.squish
        #{insert_head}
        SELECT #{uid}, #{rid}, gm.id, #{now}, #{now}
          FROM group_messages gm
          LEFT JOIN group_message_reads gmr
                 ON gmr.group_message_id = gm.id
                AND gmr.user_id = #{uid}
         WHERE gm.chat_room_id = #{rid}
           AND gm.user_id <> #{uid}
           #{cond_joined ? "AND gm.created_at >= #{cond_joined}" : ''}
           AND gmr.id IS NULL
        #{on_conflict}
      SQL

      ActiveRecord::Base.connection.execute(sql)
    rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordNotUnique
      # ユニーク衝突は黙ってスルー
      nil
    end

    def joined_at_for(user, room)
      ChatRoomUser.where(user_id: user.id, chat_room_id: room.id).pick(:created_at)
    end

    # --------- 左リスト更新（互換維持） ---------
    def refresh_left_list_for!(user)
      if defined?(GroupChatListBroadcaster)
        GroupChatListBroadcaster.push_for_user(user)
      else
        return unless @chat_room

        item_html = render_to_string(
          partial: 'layouts/leftSide/group_chat/group_chat_item',
          locals: { chat_room: @chat_room, current_user: user },
          formats: [:html],
          layout: false
        )

        # 既存の replace / reorder / unread_count を踏襲
        ActionCable.server.broadcast(
          "user_#{user.id}_group_chat",
          { type: 'replace', chat_room_id: @chat_room.id, html: item_html }
        )
        ActionCable.server.broadcast(
          "user_#{user.id}_group_chat",
          { type: 'reorder', chat_room_id: @chat_room.id }
        )
        ActionCable.server.broadcast(
          "user_#{user.id}_group_chat",
          { type: 'unread_count', chat_room_id: @chat_room.id, html: '' }
        )
      end
    end

    # --------- 並べ替え ---------
    def sort_rooms(current_room_id)
      @chat_rooms.sort_by do |room|
        is_current      = room.id == current_room_id ? 0 : 1
        latest_activity = @latest_map[room.id] || room.created_at
        [is_current, -latest_activity.to_i]
      end
    end
  end
end
