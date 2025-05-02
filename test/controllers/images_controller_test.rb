require "test_helper"

class ImagesControllerTest < ActionDispatch::IntegrationTest
  test "should get ogp" do
    get images_ogp_url
    assert_response :success
  end
end
