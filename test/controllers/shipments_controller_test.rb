require "test_helper"
require "json"

class ShipmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org = create(:organization)
    @role = create(:role, organization: @org)
    @user = create(:user, organization: @org, role: @role, password: "password")
    grant("shipments", "view")
    grant("shipments", "update")
    grant("shipment_documents", "update")
    grant("shipment_documents", "approve")
    grant("shipment_documents", "waive")
    sign_in
    @shipment = create(:shipment, purchase_order: create(:purchase_order, organization: @org))
  end

  test "index and show require permissions and render successfully" do
    get shipments_path(org_slug: @org.subdomain)
    assert_response :success

    get shipment_path(org_slug: @org.subdomain, id: @shipment)
    assert_response :success
  end

  test "index includes pagination props and clamps out of range pages" do
    2.times { create(:shipment, purchase_order: create(:purchase_order, organization: @org)) }

    get shipments_path(org_slug: @org.subdomain), params: { page: 99, per_page: 1 }, headers: { "X-Inertia" => "true" }

    assert_response :success
    pagination = inertia_props.fetch("pagination")
    assert_equal 3, pagination.fetch("page")
    assert_equal 1, pagination.fetch("per_page")
    assert_equal 3, pagination.fetch("total_count")
    assert_equal 3, pagination.fetch("total_pages")
    assert_equal 2, pagination.fetch("prev_page")
    assert_nil pagination.fetch("next_page")
    assert_equal 1, inertia_props.fetch("shipments").size
  end

  test "approves and waives shipment documents" do
    document = @shipment.shipment_documents.first

    post approve_shipment_document_path(org_slug: @org.subdomain, id: document)
    assert_redirected_to shipment_path(org_slug: @org.subdomain, id: @shipment)
    assert_equal "approved", document.reload.status

    other_document = @shipment.shipment_documents.where.not(id: document.id).first
    post waive_shipment_document_path(org_slug: @org.subdomain, id: other_document)
    assert_redirected_to shipment_path(org_slug: @org.subdomain, id: @shipment)
    assert_equal "waived", other_document.reload.status
  end

  test "validates source of truth checks" do
    previous_count = @shipment.source_of_truth_checks.count
    post validate_source_of_truth_shipment_path(org_slug: @org.subdomain, id: @shipment)

    assert_redirected_to shipment_path(org_slug: @org.subdomain, id: @shipment)
    assert_operator @shipment.source_of_truth_checks.count, :>, previous_count
  end

  private

    def grant(resource, action)
      permission = Permission.find_or_create_by!(resource: resource, action: action)
      @role.permissions << permission unless @role.permissions.include?(permission)
    end

    def sign_in
      post login_path(org_slug: @org.subdomain), params: {
        email_address: @user.email_address,
        password: "password"
      }
    end

    def inertia_props
      JSON.parse(response.body).fetch("props")
    end
end
