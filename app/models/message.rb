class Message < ApplicationRecord
  belongs_to :user
  belongs_to :chat
  after_create_commit -> { chat.touch(:updated_at) } # メッセージが送られたらチャットの更新日時を変更

  private

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
