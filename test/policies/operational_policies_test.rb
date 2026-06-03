require "test_helper"

class OperationalPoliciesTest < ActiveSupport::TestCase
  setup do
    @org = create(:organization)
    @role = create(:role, organization: @org)
    @user = create(:user, organization: @org, role: @role)
  end

  test "shipment policy uses shipment permissions" do
    assert_not ShipmentPolicy.new(@user, Shipment).index?
    grant("shipments", "view")
    assert ShipmentPolicy.new(@user, Shipment).index?
  end

  test "shipment document policy uses approve and waive permissions" do
    policy = ShipmentDocumentPolicy.new(@user, :shipment_document)
    assert_not policy.approve?
    assert_not policy.waive?

    grant("shipment_documents", "approve")
    grant("shipment_documents", "waive")

    assert ShipmentDocumentPolicy.new(@user, :shipment_document).approve?
    assert ShipmentDocumentPolicy.new(@user, :shipment_document).waive?
  end

  test "master data policies use their own resources" do
    [
      [ TradingPartnerPolicy, "trading_partners" ],
      [ MasterAgreementPolicy, "master_agreements" ],
      [ PurchaseOrderPolicy, "purchase_orders" ],
    ].each do |policy_class, resource|
      assert_not policy_class.new(@user, Object).index?
      grant(resource, "view")
      assert policy_class.new(@user, Object).index?
    end
  end

  test "policy scopes filter organization owned operational records" do
    other_org = create(:organization)
    own_partner = create(:trading_partner, organization: @org)
    other_partner = create(:trading_partner, organization: other_org)
    own_agreement = create(:master_agreement, organization: @org, trading_partner: own_partner)
    other_agreement = create(:master_agreement, organization: other_org, trading_partner: other_partner)
    own_order = create(:purchase_order, organization: @org, trading_partner: own_partner, master_agreement: own_agreement)
    other_order = create(:purchase_order, organization: other_org, trading_partner: other_partner, master_agreement: other_agreement)
    own_shipment = create(:shipment, organization: @org, purchase_order: own_order)
    other_shipment = create(:shipment, organization: other_org, purchase_order: other_order)
    own_document = own_shipment.shipment_documents.first
    other_document = other_shipment.shipment_documents.first

    assert_scope_ids TradingPartnerPolicy, TradingPartner.all, own_partner, other_partner
    assert_scope_ids MasterAgreementPolicy, MasterAgreement.all, own_agreement, other_agreement
    assert_scope_ids PurchaseOrderPolicy, PurchaseOrder.all, own_order, other_order
    assert_scope_ids ShipmentPolicy, Shipment.all, own_shipment, other_shipment
    assert_scope_ids ShipmentDocumentPolicy, ShipmentDocument.all, own_document, other_document
  end

  test "organization policy scopes return none for users without organization" do
    user = create(:user, :superadmin)

    assert_empty ShipmentPolicy::Scope.new(user, Shipment.all).resolve
    assert_empty ShipmentDocumentPolicy::Scope.new(user, ShipmentDocument.all).resolve
  end

  private

    def grant(resource, action)
      permission = Permission.find_or_create_by!(resource: resource, action: action)
      @role.permissions << permission unless @role.permissions.include?(permission)
    end

    def assert_scope_ids(policy_class, scope, included_record, excluded_record)
      ids = policy_class::Scope.new(@user, scope).resolve.ids

      assert_includes ids, included_record.id
      assert_not_includes ids, excluded_record.id
    end
end
