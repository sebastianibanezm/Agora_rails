require "test_helper"

class WorkflowPhaseTest < ActiveSupport::TestCase
  test "requires organization scoped unique position and code" do
    org = create(:organization)
    phase = create(:workflow_phase, organization: org, position: 99, code: "custom_phase")

    duplicate = build(:workflow_phase, organization: org, position: phase.position, code: phase.code)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:position], "has already been taken"
    assert_includes duplicate.errors[:code], "has already been taken"

    other_org_duplicate = build(:workflow_phase, organization: create(:organization), position: phase.position, code: phase.code)
    assert other_org_duplicate.valid?
  end
end
