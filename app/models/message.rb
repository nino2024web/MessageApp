class Message < ApplicationRecord
  belongs_to :user
  belongs_to :chat

  has_many :message_reads, dependent: :destroy

  after_create_commit -> { chat.touch(:updated_at) } # メッセージが送られたらチャットの更新日時を変更
  after_create_commit :touch_chat_and_broadcast

  # 投稿文字数最大800文字
  validates :content, presence: true, length: { maximum: 800 }

  after_create_commit do
    # チャット画面更新
    broadcast_append_to "chat_#{chat.id}", target: 'chat-messages', partial: 'layouts/center/message',
                                           locals: { message: self, current_user_id: user.id }

    # チャット一覧更新
    chat.users.each do |user|
      broadcast_replace_to(
        "chat_list_#{user.id}",
        target: 'chat-list',
        partial: 'layouts/leftSide/chat_list',
        locals: { all_chats: user.chats.order(updated_at: :desc), current_user: user }
      )
    end
  end

  private

  def touch_chat_and_broadcast
    chat.touch
    broadcast_chat_list
  end

  def broadcast_chat_list
    chat.users.each do |user|
      Turbo::StreamsChannel.broadcast_replace_to(
        "friend_list_#{user.id}",
        target: 'chat-list',
        partial: 'layouts/leftSide/chat_list',
        locals: { all_chats: user.chats.order(updated_at: :desc), current_user: user }
      )
    end
  end

  def broadcast_update
    chat_users = chat.users
    chat_users.each do |user|
      Turbo::StreamsChannel.broadcast_replace_to(
        "recent_chats_#{user.id}",
        target: 'recent-chats',
        partial: 'users/recent_chats',
        locals: { recent_chats: user.chats.order(updated_at: :desc).limit(5) }
      )
    end
  end
end
