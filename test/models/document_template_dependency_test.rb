require "test_helper"

class DocumentTemplateDependencyTest < ActiveSupport::TestCase
  test "allows valid directed dependency and rejects self dependency" do
    org = create(:organization)
    po = org.document_templates.find_by!(code: "purchase_order")
    booking = org.document_templates.find_by!(code: "booking_confirmation")

    dependency = build(:document_template_dependency,
                       organization: org,
                       prerequisite_document_template: po,
                       dependent_document_template: booking)
    assert dependency.valid?

    self_dependency = build(:document_template_dependency,
                            organization: org,
                            prerequisite_document_template: po,
                            dependent_document_template: po)
    assert_not self_dependency.valid?
    assert_includes self_dependency.errors[:dependent_document_template], "cannot depend on itself"
  end

  test "rejects dependencies across organizations" do
    org = create(:organization)
    other_org = create(:organization)
    dependency = build(:document_template_dependency,
                       organization: org,
                       prerequisite_document_template: org.document_templates.first,
                       dependent_document_template: other_org.document_templates.first)

    assert_not dependency.valid?
    assert_includes dependency.errors[:base], "document templates must belong to the same organization"
  end
end
