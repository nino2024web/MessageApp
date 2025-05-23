require "test_helper"

class GroupMessagesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get group_messages_create_url
    assert_response :success
  end
end
