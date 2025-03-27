class FriendsController < ApplicationController
  before_action :authenticate_user!

  def index
    @friends = current_user.friends
  end

  def search
    @users = User.where('name LIKE ?', "%#{params[:name]}%")
    render :index
  end

  def create
    friend = User.find(params[:friend_id])
    current_user.friends << friend unless current_user.friends.include?(friend)
    redirect_to friends_path
  end

  def destroy
    friend = User.find(params[:id])
    current_user.friends.destroy(friend)
    redirect_to friends_path
  end
end
