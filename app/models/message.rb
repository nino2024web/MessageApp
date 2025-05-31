class Message < ApplicationRecord
  belongs_to :user
  belongs_to :chat

  after_create_commit -> { chat.touch(:updated_at) } # メッセージが送られたらチャットの更新日時を変更

  # 投稿文字数最大800文字
  validates :content, presence: true, length: { maximum: 800 }

  after_create_commit do
    # チャット画面更新
    broadcast_append_to "chat_#{chat.id}",
                        target: 'chat-messages',
                        partial: 'layouts/center/personal_chat/message',
                        locals: { message: self, current_user: user }

    # チャット一覧更新
    chat_users = [chat.user1, chat.user2]
    chat_users.each do |u|
      Turbo::StreamsChannel.broadcast_replace_to(
        "chat_list_#{u.id}",
        target: 'chat-list',
        partial: 'layouts/leftSide/personal_chat/chat_list',
        locals: { all_chats: u.chats.order(updated_at: :desc), current_user: u }
      )
    end
  end
end
