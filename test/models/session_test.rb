require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "is invalid without user" do
    session = Session.new(ip_address: "127.0.0.1", expires_at: 1.hour.from_now)
    assert_not session.valid?
  end

  test "is valid with a user and expiry" do
    session = Session.new(user: create(:user, organization: create(:organization)), expires_at: 1.hour.from_now)
    assert session.valid?
  end

  test "destroying user destroys sessions" do
    user = create(:user, organization: create(:organization))
    user.sessions.create!(ip_address: "127.0.0.1", expires_at: 1.hour.from_now)
    assert_difference "Session.count", -1 do
      user.destroy
    end
  end

  test "active scope excludes expired sessions" do
    user = create(:user)
    active = user.sessions.create!(expires_at: 1.hour.from_now)
    expired = user.sessions.create!(expires_at: 1.minute.ago)

    assert_includes Session.active, active
    assert_not_includes Session.active, expired
    assert expired.expired?
  end
end
