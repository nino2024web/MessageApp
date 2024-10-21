class FriendsController < ApplicationController
  before_action :authenticate_user!

  def search
    # Searching for friends by name
    @friends = User.where("name LIKE ?", "%#{params[:query]}%")

    # Rendering only the search results, not the full page
    render partial: "friends/friend_search_results", locals: { friends: @friends }
  end
end
