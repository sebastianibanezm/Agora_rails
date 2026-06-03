require "test_helper"

class DocumentFieldDefinitionTest < ActiveSupport::TestCase
  test "validates scoped key and value type" do
    org = create(:organization)
    field = create(:document_field_definition, organization: org, key: "custom_field")

    duplicate = build(:document_field_definition, organization: org, key: field.key)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:key], "has already been taken"

    duplicate.organization = create(:organization)
    assert duplicate.valid?

    duplicate.value_type = "blob"
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:value_type], "is not included in the list"
  end
end
