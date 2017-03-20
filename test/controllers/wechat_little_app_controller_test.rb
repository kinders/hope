require 'test_helper'

class WechatLittleAppControllerTest < ActionDispatch::IntegrationTest
# class SessionsControllerTest < ActionDispatch::IntegrationTest

=begin
  test "should get login" do
    get sessions_login_url
    assert_response :success
  end

  test "should get notify" do
    get sessions_notify_url
    assert_response :success
  end
=end

  test "should post home" do
    post sessions_home_url, params: { token: '111' }
    assert_response :success
  end


end
