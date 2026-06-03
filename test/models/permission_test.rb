require "test_helper"

class PermissionTest < ActiveSupport::TestCase
  test "is invalid without resource" do
    perm = build(:permission, resource: nil)
    assert_not perm.valid?
    assert_includes perm.errors[:resource], "can't be blank"
  end

  test "is invalid without action" do
    perm = build(:permission, action: nil)
    assert_not perm.valid?
    assert_includes perm.errors[:action], "can't be blank"
  end

  test "is invalid when resource+action pair is duplicated" do
    create(:permission, resource: "documents", action: "view")
    dup = build(:permission, resource: "documents", action: "view")
    assert_not dup.valid?
    assert_includes dup.errors[:action], "has already been taken"
  end

  test "allows same action on different resources" do
    create(:permission, resource: "documents", action: "view")
    perm = build(:permission, resource: "members", action: "view")
    assert perm.valid?
  end

  test "to_s returns resource:action" do
    perm = build(:permission, resource: "documents", action: "create")
    assert_equal "documents:create", perm.to_s
  end
end
