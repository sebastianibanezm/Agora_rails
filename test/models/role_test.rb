require "test_helper"

class RoleTest < ActiveSupport::TestCase
  test "is invalid without name" do
    role = build(:role, name: nil)
    assert_not role.valid?
    assert_includes role.errors[:name], "can't be blank"
  end

  test "is invalid when name is duplicated within same organization" do
    org = create(:organization)
    create(:role, name: "manager", organization: org)
    dup = build(:role, name: "manager", organization: org)
    assert_not dup.valid?
    assert_includes dup.errors[:name], "has already been taken"
  end

  test "allows same name across different organizations" do
    create(:role, name: "manager", organization: create(:organization))
    role = build(:role, name: "manager", organization: create(:organization))
    assert role.valid?
  end

  test "is invalid without organization" do
    role = build(:role, organization: nil)
    assert_not role.valid?
  end

  test "can? returns true when role has the permission" do
    perm = create(:permission, resource: "documents", action: "create")
    role = create(:role)
    role.permissions << perm
    assert role.can?("documents", "create")
  end

  test "can? returns false when role does not have the permission" do
    create(:permission, resource: "documents", action: "destroy")
    role = create(:role)
    assert_not role.can?("documents", "destroy")
  end

  test "can? accepts symbol action" do
    perm = create(:permission, resource: "members", action: "invite")
    role = create(:role)
    role.permissions << perm
    assert role.can?("members", :invite)
  end

  test "can? returns false for unknown permission" do
    role = create(:role)
    assert_not role.can?("billing", "view")
  end
end
