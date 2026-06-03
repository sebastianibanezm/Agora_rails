require "test_helper"

class DocumentPolicyTest < ActiveSupport::TestCase
  setup do
    @org  = create(:organization)
    @role = create(:role, organization: @org)
    @user = create(:user, organization: @org, role: @role)

    %w[view create update destroy].each do |action|
      Permission.find_or_create_by!(resource: "documents", action: action)
    end
  end

  # Helper: build a policy instance for @user against a fake record
  def policy(user = @user)
    DocumentPolicy.new(user, :document)
  end

  def grant(*actions)
    actions.each do |action|
      perm = Permission.find_by!(resource: "documents", action: action)
      @role.permissions << perm unless @role.permissions.include?(perm)
    end
  end

  test "index? and show? require documents:view" do
    assert_not policy.index?
    assert_not policy.show?
    grant("view")
    assert policy.index?
    assert policy.show?
  end

  test "new? and create? require documents:create" do
    assert_not policy.new?
    assert_not policy.create?
    grant("create")
    assert policy.new?
    assert policy.create?
  end

  test "edit? and update? require documents:update" do
    assert_not policy.edit?
    assert_not policy.update?
    grant("update")
    assert policy.edit?
    assert policy.update?
  end

  test "destroy? requires documents:destroy" do
    assert_not policy.destroy?
    grant("destroy")
    assert policy.destroy?
  end

  test "raises NotAuthorizedError when user is nil" do
    assert_raises(Pundit::NotAuthorizedError) { DocumentPolicy.new(nil, :document) }
  end

  test "user with no role is denied all actions" do
    user = create(:user, organization: @org, role: nil)
    p = DocumentPolicy.new(user, :document)
    assert_not p.index?
    assert_not p.create?
    assert_not p.update?
    assert_not p.destroy?
  end
end
