class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show]

  def show
    @all_chats = current_user.chats.order(updated_at: :desc) # 全てのチャット
    @all_friends = current_user.friends.order(name: :asc) # 友達リスト
    @search_results = [] # 検索結果初期化
    @friend_requests = current_user.received_friend_requests.where(status: 'pending') # 友達検索リクエスト取得
  end

  def search
    @search_results = params[:name].present? ? perform_search : []
    render partial: 'layouts/leftSide/search_results', locals: { search_results: @search_results }
  end

  def start_chat
    friend = User.find(params[:id])
    chat = current_user.find_or_create_chat(friend)
    redirect_to chat_path(chat)
  end

  private

  def perform_search
    blocked_user_ids = current_user.blocked_users.pluck(:id) + current_user.blockers.pluck(:id)
    User.search_by_name(params[:name])
        .where.not(id: blocked_user_ids + [current_user.id])
  end

  def set_user
    @user = User.find(params[:id])
  end
end
