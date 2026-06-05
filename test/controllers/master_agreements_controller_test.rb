require "test_helper"
require "json"

class MasterAgreementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org = create(:organization)
    @role = create(:role, organization: @org)
    @user = create(:user, organization: @org, role: @role, password: "password")
    grant("master_agreements", "view")
    grant("master_agreements", "update")
    grant("shipment_documents", "approve")
    grant("shipment_documents", "waive")
    sign_in

    @agreement = create(:master_agreement, organization: @org)
    @purchase_order = create(:purchase_order,
                             organization: @org,
                             trading_partner: @agreement.trading_partner,
                             master_agreement: @agreement)
    @shipment = create(:shipment, purchase_order: @purchase_order)
    CreateShipmentWorkflow.call!(@shipment)
  end

  test "tenant root and master agreement pages render contract-first workspace" do
    get org_root_path(org_slug: @org.subdomain)
    assert_response :success

    get master_agreements_path(org_slug: @org.subdomain), headers: { "X-Inertia" => "true" }
    assert_response :success
    assert_equal "MasterAgreements/Index", inertia_component
    assert_equal @agreement.agreement_number, inertia_props.fetch("agreements").first.fetch("agreement_number")

    get master_agreement_path(org_slug: @org.subdomain, id: @agreement), headers: { "X-Inertia" => "true" }
    assert_response :success
    assert_equal "MasterAgreements/Show", inertia_component
    assert_equal @agreement.agreement_number, inertia_props.fetch("agreement").fetch("agreement_number")
    assert_equal 1, inertia_props.fetch("purchase_orders").size
    assert_equal [], inertia_props.fetch("contract_packet").fetch("documents")
  end

  test "contract packet upload and review expose extracted data" do
    post master_agreement_master_agreement_documents_path(org_slug: @org.subdomain, master_agreement_id: @agreement),
         params: {
           master_agreement_document: {
             title: "Frozen Fruit Schedule",
             document_kind: "schedule",
             file: Rack::Test::UploadedFile.new(StringIO.new("%PDF-1.4\n"), "application/pdf", original_filename: "schedule.pdf")
           }
         }

    assert_redirected_to master_agreement_url(org_slug: @org.subdomain, id: @agreement)
    document = @agreement.master_agreement_documents.last
    assert_equal "Frozen Fruit Schedule", document.title
    assert document.file.attached?

    value = create(:master_agreement_extracted_value,
                   organization: @org,
                   master_agreement: @agreement,
                   master_agreement_document: document,
                   field_key: "payment_terms",
                   raw_value: "2% 15 Net 30 Days")

    patch review_master_agreement_master_agreement_document_path(org_slug: @org.subdomain,
                                                                  master_agreement_id: @agreement,
                                                                  id: document),
          params: { review_status: "confirmed" }

    assert_redirected_to master_agreement_url(org_slug: @org.subdomain, id: @agreement)
    assert_equal "confirmed", value.reload.review_status
    assert_equal "2% 15 Net 30 Days", @agreement.reload.payment_terms

    get master_agreement_path(org_slug: @org.subdomain, id: @agreement), headers: { "X-Inertia" => "true" }
    assert_equal 1, inertia_props.fetch("contract_packet").fetch("documents").size
    assert_equal "confirmed", inertia_props.fetch("contract_packet").fetch("extracted_values").first.fetch("review_status")
  end

  test "contract document actions return to the contract page when invoked from there" do
    document = @agreement.shipment_documents.first

    post approve_shipment_document_path(org_slug: @org.subdomain, id: document),
         headers: { "HTTP_REFERER" => master_agreement_url(org_slug: @org.subdomain, id: @agreement) }

    assert_redirected_to master_agreement_url(org_slug: @org.subdomain, id: @agreement)
    assert_equal "approved", document.reload.status
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

    def inertia_component
      JSON.parse(response.body).fetch("component")
    end

    def inertia_props
      JSON.parse(response.body).fetch("props")
    end
end
