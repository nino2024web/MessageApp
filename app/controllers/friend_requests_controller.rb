class FriendRequestsController < ApplicationController
  before_action :authenticate_user!

  def index
    @friend_requests = current_user.received_friend_requests
                                   .pending
                                   .where.not(sender_id: current_user.blocked_users.ids + current_user.blockers.ids)
    render partial: 'layouts/leftSide/personal_chat/friend_requests', locals: { friend_requests: @friend_requests }
  end

  def create
    receiver = User.find(params[:receiver_id])

    # すでに友達 or リクエスト中なら無視
    if current_user.friends.include?(receiver) ||
       current_user.sent_friend_requests.where(receiver_id: receiver.id, status: 'pending').exists?
      head :conflict and return
    end

    friend_request = current_user.sent_friend_requests.find_by(receiver_id: receiver.id)

    if friend_request.present?
      if friend_request.status == 'pending'
        head :conflict and return
      else
        friend_request.update(status: 'pending')
      end
    else
      friend_request = current_user.sent_friend_requests.build(receiver: receiver)
      friend_request.save
    end

    # 送信者側
    html_for_sender = render_to_string(
      partial: 'layouts/leftSide/personal_chat/request_button',
      locals: {
        user: receiver,
        current_user: current_user,
        friend_request: friend_request
      }
    )

    # 相手側
    html_for_receiver = render_to_string(
      partial: 'layouts/leftSide/personal_chat/request_button',
      locals: {
        user: current_user,
        current_user: receiver,
        friend_request: friend_request
      }
    )

    # receiverに送る
    ActionCable.server.broadcast(
      "friend_requests_btn_#{receiver.id}",
      {
        action: 'reload_requests',
        userId: current_user.id,
        html: html_for_receiver
      }
    )

    render html: html_for_sender.html_safe
  end

  def update
    @friend_request = FriendRequest.find(params[:id])
    process_request(@friend_request)

    if params[:status] == 'accepted'
      broadcast_friend_list(@friend_request.sender)
      broadcast_friend_list(@friend_request.receiver)

      html_for_receiver = render_to_string(
        partial: 'layouts/leftSide/personal_chat/request_button',
        locals: {
          user: @friend_request.sender,
          current_user: @friend_request.receiver,
          friend_request: @friend_request
        }
      )

      html_for_sender = render_to_string(
        partial: 'layouts/leftSide/personal_chat/request_button',
        locals: {
          user: @friend_request.receiver,
          current_user: @friend_request.sender,
          friend_request: @friend_request
        }
      )

      ActionCable.server.broadcast(
        "friend_requests_btn_#{@friend_request.sender.id}",
        {
          action: 'reload_requests',
          userId: @friend_request.receiver.id,
          html: html_for_sender
        }
      )

      ActionCable.server.broadcast(
        "friend_requests_btn_#{@friend_request.receiver.id}",
        {
          action: 'reload_requests',
          userId: @friend_request.sender.id,
          html: html_for_receiver
        }
      )

    elsif params[:status] == 'rejected'
      ActionCable.server.broadcast(
        "friend_requests_btn_#{@friend_request.sender.id}",
        { action: 'reload_requests' }
      )

      broadcast_search_results(@friend_request.receiver)
      broadcast_search_results(@friend_request.sender)

    else
      # 拒否時 → リクエスト一覧のみ更新、ボタンは変更しない
      broadcast_friend_requests(@friend_request.receiver)
    end
    head :ok
  end

  private

  def process_request(request)
    case params[:status]
    when 'accepted'
      request.update(status: 'accepted')
      create_friendship(request)
    when 'rejected'
      request.update(status: 'rejected')
    end
  end

  def create_friendship(request)
    Friendship.create(user: request.sender, friend: request.receiver)
    Friendship.create(user: request.receiver, friend: request.sender)
  end

  def broadcast_friend_list(user)
    html = render_to_string(
      partial: 'layouts/leftSide/personal_chat/friend_list',
      locals: { all_friends: user.friends }
    )
    Rails.logger.debug "🔁 Broadcasting to friend_list_#{user.id}"
    ActionCable.server.broadcast("friend_list_#{user.id}", html)
  end

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
