class FriendsController < ApplicationController
  def index
    @recent_friends = current_user.recent_friends.limit(5)
    @all_friends = current_user.all_friends
  end
end
