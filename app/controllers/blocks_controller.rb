class BlocksController < ApplicationController
  before_action :authenticate_user!
  def create
    blocked_user = User.find(params[:blocked_user_id])

    # リクエスト削除
    FriendRequest.where(sender: blocked_user, receiver: current_user).destroy_all
    FriendRequest.where(sender: current_user, receiver: blocked_user).destroy_all

    current_user.blocks.create(blocked_user:)
    redirect_back fallback_location: root_path
  end

  def destroy
    block = current_user.blocks.find_by(blocked_user_id: params[:id])
    block.destroy if block
    redirect_back fallback_location: root_path
  end
end
