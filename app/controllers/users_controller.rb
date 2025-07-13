class UsersController < ApplicationController
  before_action :authenticate_user!

  def search
    @search_results = params[:name].present? ? perform_search : []

    html = render_to_string(
      partial: 'layouts/leftSide/personal_chat/search_results',
      formats: [:html],
      locals: { search_results: @search_results }
    )

    ActionCable.server.broadcast("search_results_#{current_user.id}", html)
    head :ok
  end

  def start_chat
    friend = User.find(params[:id])
    chat = find_or_create_chat(friend)
    redirect_to personal_user_path(current_user, chat_id: chat.id)
  end

  private

  def perform_search
    blocked_ids = current_user.blocked_users.pluck(:id) + current_user.blockers.pluck(:id)
    User.search_by_name(params[:name])
        .where.not(id: blocked_ids + [current_user.id])
  end

  def find_or_create_chat(friend)
    chat = Chat.between(current_user, friend)
    return chat if chat

    Chat.create(user1: current_user, user2: friend, name: "#{current_user.name} & #{friend.name}")
  end
end
