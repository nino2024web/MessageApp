module Users
  class PersonalController < ApplicationController
    before_action :authenticate_user!
    before_action :set_user

    def show
      load_user_data
      load_chat_data if params[:chat_id].present?
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def load_user_data
      @all_chats = @user.chats.order(updated_at: :desc)
      @all_friends = @user.friends.order(:name)
      @friend_requests = @user.received_friend_requests.where(status: 'pending')
      @search_results = []
    end

    def load_chat_data
      @chat = Chat.includes(messages: :user).find_by(id: params[:chat_id])
      @messages = @chat.messages.includes(:user).order(:created_at)
      @message = Message.new
    end
  end
end
