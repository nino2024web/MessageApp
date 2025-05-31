module Users
  class PersonalController < ApplicationController
    before_action :authenticate_user!
    before_action :set_user
    before_action :set_chat, only: [:show]
    before_action :load_chat_data, if: -> { @chat.present? }

    def show
      load_user_data
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def set_chat
      @chat = Chat.includes(messages: :user).find_by(id: params[:chat_id])
    end

    def load_user_data
      @all_chats = @user.chats.order(updated_at: :desc)
      @all_friends = @user.friends.order(:name)
      @friend_requests = @user.received_friend_requests.pending
      @search_results = []
    end

    def load_chat_data
      @messages = @chat.messages.includes(:user).order(:created_at)
      @message = Message.new

      # ✅ 既読フラグ更新
      @chat.messages
           .where.not(user_id: current_user.id)
           .where(read: [false, nil])
           .update_all(read: true)
    end
  end
end
