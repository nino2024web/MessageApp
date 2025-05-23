class UsersController < ApplicationController
  before_action :authenticate_user!

  def search
    @search_results = params[:name].present? ? perform_search : []
    handle_search_response
  end

  def start_chat
    friend = User.find(params[:id])
    chat = find_or_create_chat(friend)
    redirect_to personal_user_path(current_user, chat_id: chat.id)
  end

  private

  def handle_search_response
    respond_to do |format|
      format.turbo_stream { render_turbo_stream }
      format.html { render_html }
    end
  end

  def render_turbo_stream
    render turbo_stream: turbo_stream.replace(
      'search-results',
      partial: 'layouts/leftSide/personal_chat/search_results',
      locals: { search_results: @search_results }
    )
  end

  def render_html
    render partial: 'layouts/leftSide/personal_chat/search_results',
           locals: { search_results: @search_results }
  end

  def perform_search
    blocked_ids = current_user.blocked_users.pluck(:id) + current_user.blockers.pluck(:id)
    User.search_by_name(params[:name])
        .where.not(id: blocked_ids + [current_user.id])
  end

  def find_or_create_chat(friend)
    chat = Chat.between(current_user, friend)
    return chat if chat

    chat = Chat.create(user1: current_user, user2: friend, name: "#{current_user.name} & #{friend.name}")
    ChatUser.create(chat: chat, user: current_user)
    ChatUser.create(chat: chat, user: friend)
    chat
  end
end
