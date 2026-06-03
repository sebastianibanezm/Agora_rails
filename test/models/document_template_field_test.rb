require "test_helper"

class DocumentTemplateFieldTest < ActiveSupport::TestCase
  test "requires linked records from the same organization" do
    org = create(:organization)
    other_org = create(:organization)
    template_field = build(:document_template_field,
                           organization: org,
                           document_template: org.document_templates.first,
                           document_field_definition: other_org.document_field_definitions.first)

    assert_not template_field.valid?
    assert_includes template_field.errors[:base], "linked records must belong to the same organization"
  end
end
