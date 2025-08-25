class GroupMessagesController < ApplicationController
  before_action :authenticate_user!

  # POST /group_messages
  def create
    @group_message = current_user.group_messages.build(group_message_params)
    @chat_room     = @group_message&.chat_room
    return render_json_error('chat_room_id が不正です', :bad_request) unless @chat_room

    # ルーム所属チェック
    unless ChatRoomUser.exists?(user_id: current_user.id, chat_room_id: @chat_room.id)
      return render_json_error('権限がありません', :forbidden)
    end

    # DB 書き込み
    ActiveRecord::Base.transaction { @group_message.save! }

    # commit 後：中央にブロードキャスト
    rendered_html = render_to_string(
      partial: 'layouts/center/group_chat/group_message',
      locals: { message: @group_message, current_user: current_user },
      formats: [:html],
      layout: false
    )
    ActionCable.server.broadcast(
      "group_chat_#{@chat_room.id}",
      { type: 'message', chat_room_id: @chat_room.id, html: rendered_html }
    )

    # 左リスト更新（全参加者）
    @chat_room.users.find_each do |user|
      # 項目の器を全置換（数字は描かない）
      item_html = render_to_string(
        partial: 'layouts/leftSide/group_chat/group_chat_item',
        locals: { chat_room: @chat_room, current_user: user },
        formats: [:html],
        layout: false
      )
      ActionCable.server.broadcast("user_#{user.id}_group_chat",
                                   { type: 'replace', chat_room_id: @chat_room.id, html: item_html })
      ActionCable.server.broadcast("user_#{user.id}_group_chat",
                                   { type: 'reorder', chat_room_id: @chat_room.id })

      # 未読数をイベントで差し込み
      unread     = compute_unread_count(@chat_room.id, user.id)
      badge_html = unread.positive? ? view_context.tag.span("未読 #{unread}", class: 'unread-badge') : ''
      ActionCable.server.broadcast("user_#{user.id}_group_chat",
                                   { type: 'unread_count', chat_room_id: @chat_room.id, html: badge_html })
    end

    render json: { ok: true, id: @group_message.id }
  rescue StandardError => e
    Rails.logger.error("[group_messages#create] #{e.class}: #{e.message}\n#{e.backtrace&.first}")
    render_json_error('投稿時にエラーが発生しました', :internal_server_error)
  end

  # POST /group_messages/mark_as_read
  def mark_as_read
    chat_room_id = params[:chat_room_id].to_i
    return render json: { ok: false, errors: ['chat_room_id が必要です'] }, status: :bad_request if chat_room_id <= 0

    chat_room = ChatRoom.find_by(id: chat_room_id)
    return render json: { ok: false, errors: ['chat_room が見つかりません'] }, status: :not_found unless chat_room

    unless ChatRoomUser.exists?(user_id: current_user.id, chat_room_id: chat_room_id)
      return render json: { ok: false, errors: ['権限がありません'] }, status: :forbidden
    end

    # SQLite / PostgreSQL 両対応の一括既読（重複は無視）
    mark_room_as_read_for!(chat_room, current_user)

    # 自分の左アイテムを器で置換 & バッジ0
    item_html = render_to_string(
      partial: 'layouts/leftSide/group_chat/group_chat_item',
      locals: { chat_room: chat_room, current_user: current_user },
      formats: [:html],
      layout: false
    )
    ActionCable.server.broadcast("user_#{current_user.id}_group_chat",
                                 { type: 'replace',      chat_room_id: chat_room_id, html: item_html })
    ActionCable.server.broadcast("user_#{current_user.id}_group_chat",
                                 { type: 'unread_count', chat_room_id: chat_room_id, html: '' })

    render json: { ok: true }
  rescue StandardError => e
    Rails.logger.error("[group_messages#mark_as_read] #{e.class}: #{e.message}\n#{e.backtrace&.first}")
    render json: { ok: false, errors: ['既読処理でエラーが発生しました'] }, status: :internal_server_error
  end

  private

  def group_message_params
    params.require(:group_message).permit(:content, :chat_room_id)
  end

  # 未読数（他人の投稿だけ数える + 参加前の投稿は除外 + 既読テーブルとアンチジョイン）
  def compute_unread_count(chat_room_id, user_id)
    joined_at = ChatRoomUser.where(user_id: user_id, chat_room_id: chat_room_id).pick(:created_at)

    scope = GroupMessage.where(chat_room_id: chat_room_id)
                        .where.not(user_id: user_id)
    scope = scope.where('group_messages.created_at >= ?', joined_at) if joined_at

    scope.joins(<<~SQL.squish)
      LEFT JOIN group_message_reads gmr
             ON gmr.group_message_id = group_messages.id
            AND gmr.user_id = #{user_id.to_i}
    SQL
         .where('gmr.id IS NULL')
         .count
  end

  def render_json_error(msg, status_sym)
    render json: { ok: false, errors: [msg] }, status: status_sym
  end

  # 一括既読：DB方言を吸収して重複を握りつぶす
  def mark_room_as_read_for!(room, user)
    joined_at = ChatRoomUser.where(user_id: user.id, chat_room_id: room.id).pick(:created_at)

    now         = ActiveRecord::Base.connection.quote(Time.current)
    uid         = user.id.to_i
    rid         = room.id.to_i
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
    # 同時実行・制約未整備などは無視して先へ
    nil
  end
end
