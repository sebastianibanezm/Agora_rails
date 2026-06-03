require "test_helper"

class RolePermissionTest < ActiveSupport::TestCase
  test "is invalid without role" do
    rp = RolePermission.new(permission: create(:permission))
    assert_not rp.valid?
  end

  test "is invalid without permission" do
    rp = RolePermission.new(role: create(:role))
    assert_not rp.valid?
  end

  test "prevents duplicate role-permission pairs" do
    perm = create(:permission)
    role = create(:role)
    role.permissions << perm
    dup = RolePermission.new(role: role, permission: perm)
    assert_not dup.valid?
  end

  test "allows same permission on different roles" do
    perm = create(:permission)
    role_a = create(:role, organization: create(:organization))
    role_b = create(:role, organization: create(:organization))
    role_a.permissions << perm
    rp = RolePermission.new(role: role_b, permission: perm)
    assert rp.valid?
  end
end
