require "test_helper"

class DocumentTemplateTest < ActiveSupport::TestCase
  test "validates enum-like attributes and organization-scoped code" do
    org = create(:organization)
    existing = create(:document_template, organization: org, code: "custom_document")
    duplicate = build(:document_template, organization: org, workflow_phase: existing.workflow_phase, code: existing.code)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:code], "has already been taken"

    duplicate.organization = create(:organization)
    duplicate.workflow_phase = duplicate.organization.workflow_phases.first
    assert duplicate.valid?

    duplicate.document_type = "unknown"
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:document_type], "is not included in the list"
  end

  test "requires workflow phase to belong to the same organization" do
    org = create(:organization)
    other_phase = create(:organization).workflow_phases.first
    document = build(:document_template, organization: org, workflow_phase: other_phase)

    assert_not document.valid?
    assert_includes document.errors[:workflow_phase], "must belong to the same organization"
  end
end
