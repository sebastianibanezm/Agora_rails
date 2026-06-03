require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "is invalid without name" do
    org = build(:organization, name: nil)
    assert_not org.valid?
    assert_includes org.errors[:name], "can't be blank"
  end

  test "is invalid without subdomain" do
    org = build(:organization, subdomain: nil)
    assert_not org.valid?
    assert_includes org.errors[:subdomain], "can't be blank"
  end

  test "is invalid without plan" do
    org = build(:organization, plan: nil)
    assert_not org.valid?
    assert_includes org.errors[:plan], "can't be blank"
  end

  test "subdomain must be unique" do
    create(:organization, subdomain: "acme")
    org = build(:organization, subdomain: "acme")
    assert_not org.valid?
    assert_includes org.errors[:subdomain], "has already been taken"
  end

  test "plan must be in PLANS list" do
    org = build(:organization, plan: "unknown")
    assert_not org.valid?
    assert_includes org.errors[:plan], "is not included in the list"
  end

  test "subdomain rejects uppercase letters" do
    org = build(:organization, subdomain: "MyOrg")
    assert_not org.valid?
    assert_includes org.errors[:subdomain], "only lowercase letters, numbers, and hyphens"
  end

  test "subdomain rejects spaces" do
    org = build(:organization, subdomain: "my org")
    assert_not org.valid?
  end

  test "subdomain accepts lowercase letters, numbers, and hyphens" do
    org = build(:organization, subdomain: "my-org-123")
    assert org.valid?
  end

  test "feature_enabled? returns true when feature is set to true" do
    org = build(:organization, features: { "ai_extraction" => true })
    assert org.feature_enabled?(:ai_extraction)
  end

  test "feature_enabled? returns false when feature is missing" do
    org = build(:organization, features: {})
    assert_not org.feature_enabled?(:ai_extraction)
  end

  test "feature_enabled? returns false when feature is explicitly false" do
    org = build(:organization, features: { "ai_extraction" => false })
    assert_not org.feature_enabled?(:ai_extraction)
  end

  test "seeds owner, admin, and member roles after creation" do
    ensure_permissions_seeded
    org = create(:organization)
    assert_equal %w[admin member owner], org.roles.pluck(:name).sort
  end

  test "owner role gets all permissions after creation" do
    ensure_permissions_seeded
    org = create(:organization)
    owner = org.roles.find_by(name: "owner")
    assert owner.can?("documents", "view")
    assert owner.can?("documents", "destroy")
    assert owner.can?("members", "remove")
    assert owner.can?("members", "promote")
  end

  test "admin role cannot remove or promote members" do
    ensure_permissions_seeded
    org = create(:organization)
    admin = org.roles.find_by(name: "admin")
    assert_not admin.can?("members", "remove")
    assert_not admin.can?("members", "promote")
  end

  test "member role can only view and create documents, and view members" do
    ensure_permissions_seeded
    org = create(:organization)
    member = org.roles.find_by(name: "member")
    assert     member.can?("documents", "view")
    assert     member.can?("documents", "create")
    assert     member.can?("members",   "view")
    assert_not member.can?("documents", "update")
    assert_not member.can?("documents", "destroy")
    assert_not member.can?("members",   "invite")
  end

  private

    def ensure_permissions_seeded
      [
        %w[documents view], %w[documents create], %w[documents update], %w[documents destroy],
        %w[members view], %w[members invite], %w[members remove], %w[members promote]
      ].each { |r, a| Permission.find_or_create_by!(resource: r, action: a) }
    end
end
