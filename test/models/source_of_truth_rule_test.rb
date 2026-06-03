require "test_helper"

class SourceOfTruthRuleTest < ActiveSupport::TestCase
  test "requires a correction target once persisted" do
    org = create(:organization)
    rule = create(:source_of_truth_rule, organization: org)

    assert_not rule.reload.valid?
    assert_includes rule.errors[:base], "must correct at least one target document"

    create(:source_of_truth_rule_target, organization: org, source_of_truth_rule: rule)
    assert rule.reload.valid?
  end

  test "rejects linked records from different organizations" do
    org = create(:organization)
    other_org = create(:organization)
    rule = build(:source_of_truth_rule,
                 organization: org,
                 document_field_definition: org.document_field_definitions.first,
                 authoritative_document_template: other_org.document_templates.first)

    assert_not rule.valid?
    assert_includes rule.errors[:base], "linked records must belong to the same organization"
  end
end
