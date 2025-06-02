class GroupMessage < ApplicationRecord
  belongs_to :user
  belongs_to :chat_room
  has_many :group_message_reads, dependent: :destroy

  # 投稿文字数最大800文字
  validates :content, presence: true, length: { maximum: 800 }

  after_create_commit :broadcast_and_create_reads

  private

  def broadcast_and_create_reads
    # Turbo Streamにてチャット画面にメッセージ追加
    broadcast_append_to(
      "group_chat_#{chat_room_id}",
      target: 'group-messages',
      partial: 'layouts/center/group_chat/group_message',
      locals: { message: self, current_user: user }
    )

    # 未読カウントを各ユーザーに追加
    chat_room.users.where.not(id: user.id).each do |u|
      GroupMessageRead.find_or_create_by!(user: u, group_message: self, chat_room: chat_room)

      Turbo::StreamsChannel.broadcast_replace_to(
        u,
        target: "unread-count-group-#{chat_room.id}",
        partial: 'layouts/leftSide/group_chat/unread_count',
        locals: { chat_room: chat_room, current_user: u }
      )
    end
  end
end
