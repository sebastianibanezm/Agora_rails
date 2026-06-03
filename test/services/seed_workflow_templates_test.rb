require "test_helper"

class SeedWorkflowTemplatesTest < ActiveSupport::TestCase
  test "organization creation seeds workflow templates" do
    org = create(:organization)

    assert_equal 8, org.workflow_phases.count
    assert_equal 26, org.document_templates.count
    assert_equal 15, org.document_field_definitions.count
    assert_operator org.document_template_dependencies.count, :>, 40
    assert_equal 11, org.source_of_truth_rules.count
    assert_operator org.source_of_truth_rule_targets.count, :>, 20
  end

  test "service is idempotent for an organization" do
    org = create(:organization)
    counts = workflow_counts(org)

    assert_no_changes -> { workflow_counts(org) } do
      SeedWorkflowTemplates.call(org)
    end

    assert_equal counts, workflow_counts(org)
  end

  private

    def workflow_counts(org)
      [
        org.workflow_phases.count,
        org.document_templates.count,
        org.document_field_definitions.count,
        org.document_template_fields.count,
        org.document_template_dependencies.count,
        org.source_of_truth_rules.count,
        org.source_of_truth_rule_targets.count,
      ]
    end
end
