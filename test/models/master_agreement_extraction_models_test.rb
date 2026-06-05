require "test_helper"

class MasterAgreementExtractionModelsTest < ActiveSupport::TestCase
  test "master agreement document validates supported kind and tenant" do
    org = create(:organization)
    other_agreement = create(:master_agreement)
    document = build(:master_agreement_document, organization: org, master_agreement: other_agreement, document_kind: "memo")

    assert_not document.valid?
    assert_includes document.errors[:document_kind], "is not included in the list"
    assert_includes document.errors[:master_agreement], "must belong to the same organization"
  end

  test "schedule child records validate tenant boundaries" do
    org = create(:organization)
    other_schedule = create(:master_agreement_schedule)
    location = build(:master_agreement_delivery_location, organization: org, master_agreement_schedule: other_schedule)

    assert_not location.valid?
    assert_includes location.errors[:base], "linked records must belong to the same organization"
  end

  test "product price lines require commercial identifiers" do
    line = build(:master_agreement_product_price_line, participating_company: nil, product_description: nil)

    assert_not line.valid?
    assert_includes line.errors[:participating_company], "can't be blank"
    assert_includes line.errors[:product_description], "can't be blank"
  end
end
