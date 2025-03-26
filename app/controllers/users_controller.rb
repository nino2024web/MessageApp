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
    @search_results = params[:name].present? ? User.search_by_name(params[:name]) : []
    render partial: 'layouts/leftSide/search_results', locals: { search_results: @search_results }
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
