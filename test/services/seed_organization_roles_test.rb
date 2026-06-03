require "test_helper"

class SeedOrganizationRolesTest < ActiveSupport::TestCase
  setup do
    %w[view create update destroy].each { |a| Permission.find_or_create_by!(resource: "documents", action: a) }
    %w[view invite remove promote].each { |a| Permission.find_or_create_by!(resource: "members",   action: a) }
    @org = create(:organization)
  end

  test "creates owner, admin, and member roles" do
    assert_equal %w[admin member owner], @org.roles.pluck(:name).sort
  end

  test "owner has all permissions" do
    owner = @org.roles.find_by(name: "owner")
    assert_equal Permission.count, owner.permissions.count
  end

  test "admin cannot remove or promote members" do
    admin = @org.roles.find_by(name: "admin")
    assert_not admin.can?("members", "remove")
    assert_not admin.can?("members", "promote")
  end

  test "admin can do everything else" do
    admin = @org.roles.find_by(name: "admin")
    assert admin.can?("documents", "view")
    assert admin.can?("documents", "create")
    assert admin.can?("documents", "update")
    assert admin.can?("documents", "destroy")
    assert admin.can?("members",   "view")
    assert admin.can?("members",   "invite")
  end

  test "member can only view/create documents and view members" do
    member = @org.roles.find_by(name: "member")
    assert     member.can?("documents", "view")
    assert     member.can?("documents", "create")
    assert     member.can?("members",   "view")
    assert_not member.can?("documents", "update")
    assert_not member.can?("documents", "destroy")
    assert_not member.can?("members",   "invite")
  end

  test "calling twice is idempotent" do
    assert_no_difference "Role.count" do
      SeedOrganizationRoles.call(@org)
    end
    assert_equal Permission.count, @org.roles.find_by(name: "owner").permissions.count
  end
end
