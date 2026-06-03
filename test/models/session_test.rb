require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "is invalid without user" do
    session = Session.new(ip_address: "127.0.0.1")
    assert_not session.valid?
  end

  test "is valid with a user" do
    session = Session.new(user: create(:user, organization: create(:organization)))
    assert session.valid?
  end

  test "destroying user destroys sessions" do
    user = create(:user, organization: create(:organization))
    user.sessions.create!(ip_address: "127.0.0.1")
    assert_difference "Session.count", -1 do
      user.destroy
    end
  end
end
