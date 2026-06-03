require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "is invalid without email" do
    user = build(:user, email_address: nil)
    assert_not user.valid?
  end

  test "email is normalized to lowercase and stripped" do
    user = create(:user, email_address: "  Test@Example.COM  ", organization: create(:organization))
    assert_equal "test@example.com", user.email_address
  end

  test "is invalid with malformed email" do
    user = build(:user, email_address: "not-an-email")

    assert_not user.valid?
    assert_includes user.errors[:email_address], "is invalid"
  end

  test "is invalid with duplicate normalized email" do
    org = create(:organization)
    create(:user, email_address: "ana@example.com", organization: org)
    duplicate = build(:user, email_address: " ANA@example.com ", organization: org)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email_address], "has already been taken"
  end

  test "full_name returns first and last name joined" do
    user = build(:user, first_name: "Ana", last_name: "Torres")
    assert_equal "Ana Torres", user.full_name
  end

  test "full_name falls back to email when both names are blank" do
    user = build(:user, first_name: nil, last_name: nil, email_address: "ana@example.com")
    assert_equal "ana@example.com", user.full_name
  end

  test "full_name uses whichever name part is present" do
    user = build(:user, first_name: "Ana", last_name: nil)
    assert_equal "Ana", user.full_name
  end

  test "can? returns true when role grants the permission" do
    perm = create(:permission, resource: "documents", action: "create")
    role = create(:role)
    role.permissions << perm
    user = create(:user, role: role, organization: role.organization)
    assert user.can?("documents", "create")
  end

  test "can? returns false when role does not grant the permission" do
    create(:permission, resource: "documents", action: "destroy")
    role = create(:role)
    user = create(:user, role: role, organization: role.organization)
    assert_not user.can?("documents", "destroy")
  end

  test "can? returns false when user has no role" do
    user = build(:user, role: nil)
    assert_not user.can?("documents", "create")
  end

  test "superadmin defaults to false" do
    user = create(:user, organization: create(:organization))
    assert_not user.superadmin?
  end

  test "superadmin can be set to true" do
    user = create(:user, :superadmin)
    assert user.superadmin?
  end

  test "superadmin user has no organization" do
    user = create(:user, :superadmin)
    assert_nil user.organization
  end
end
