class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show]

  def show
    @user = User.find(params[:id])
    load_user_data
    load_chat_data if params[:chat_id].present?
    mark_messages_as_read if @chat.present?
  end

  def search
    @search_results = params[:name].present? ? perform_search : []
    handle_search_response
  end

  def start_chat
    friend = User.find(params[:id])
    chat = find_or_create_chat(friend)
    redirect_to user_path(current_user, chat_id: chat.id)
  end

  def mark_messages_as_read
    unread_messages = @chat.messages
                           .where.not(user_id: current_user.id)
                           .left_joins(:message_reads)
                           .where(message_reads: { user_id: nil })

    unread_messages.each do |message|
      MessageRead.create(user: current_user, message: message)
    end
  end

  private

  def find_or_create_chat(friend)
    chat = Chat.between(current_user, friend)

    unless chat
      chat = Chat.create(user1: current_user, user2: friend, name: "#{current_user.name} & #{friend.name}")
      # 🔽 ChatUser テーブルにも登録！
      ChatUser.create(chat: chat, user: current_user)
      ChatUser.create(chat: chat, user: friend)
    end

    chat
  end

  def handle_search_response
    respond_to do |format|
      format.turbo_stream { handle_turbo_stream_response }
      format.html { handle_html_response }
    end
  end

  def handle_turbo_stream_response
    render turbo_stream: turbo_stream.replace(
      'search-results',
      partial: 'layouts/leftSide/search_results',
      locals: { search_results: @search_results }
    )
  end

  def handle_html_response
    render partial: 'layouts/leftSide/search_results', locals: { search_results: @search_results }
  end

  def perform_search
    blocked_user_ids = current_user.blocked_users.pluck(:id) + current_user.blockers.pluck(:id)
    User.search_by_name(params[:name])
        .where.not(id: blocked_user_ids + [current_user.id])
  end

  def set_user
    @user = User.find(params[:id])
  end

  def load_user_data
    @all_chats = current_user.chats.order(updated_at: :desc)
    @all_friends = current_user.friends.order(name: :asc)
    @friend_requests = current_user.received_friend_requests.where(status: 'pending')
    @search_results = []
  end

  def load_chat_data
    return unless params[:chat_id].present?

    @chat = Chat.includes(messages: :user).find_by(id: params[:chat_id])
    @messages = @chat.messages.includes(:user).order(created_at: :asc)
    @message = Message.new
  end
end
