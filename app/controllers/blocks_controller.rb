class BlocksController < ApplicationController
  before_action :authenticate_user!

  def create
    blocked_user = User.find(params[:blocked_user_id])
    return if current_user.id == blocked_user.id

    # 双方向リクエスト削除
    FriendRequest.where(sender: blocked_user, receiver: current_user).destroy_all
    FriendRequest.where(sender: current_user, receiver: blocked_user).destroy_all

    Block.find_or_create_by(user: current_user, blocked_user: blocked_user)

    broadcast_friend_requests(current_user)
    broadcast_search_results(current_user)
    broadcast_search_results(blocked_user)

    head :ok
  end

  private

  def broadcast_friend_requests(user)
    html = render_to_string(
      partial: 'layouts/leftSide/personal_chat/friend_requests',
      locals: {
        friend_requests: user.received_friend_requests.pending
                            .where.not(sender_id: user.blocked_users.ids + user.blockers.ids)
      }
    )
    ActionCable.server.broadcast("friend_requests_#{user.id}", html)
  end

  def broadcast_search_results(user)
    keyword = session[:last_search_keyword] || ''
    blocked_ids = user.blocked_users.ids + user.blockers.ids

    users = User.where('name LIKE ?', "%#{keyword}%")
                .where.not(id: blocked_ids)
                .where.not(id: user.id)

    html = render_to_string(
      partial: 'layouts/leftSide/personal_chat/search_results',
      locals: {
        users: users,
        search_results: users,
        current_user: user
      }
    )

    ActionCable.server.broadcast("friend_search_#{user.id}", html)
  end
end
