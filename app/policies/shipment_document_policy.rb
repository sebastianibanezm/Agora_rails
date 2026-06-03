class ShipmentDocumentPolicy < ApplicationPolicy
  def index?   = permitted?("shipment_documents", "view")
  def show?    = permitted?("shipment_documents", "view")
  def new?     = permitted?("shipment_documents", "create")
  def create?  = permitted?("shipment_documents", "create")
  def edit?    = permitted?("shipment_documents", "update")
  def update?  = permitted?("shipment_documents", "update")
  def destroy? = permitted?("shipment_documents", "destroy")
  def approve? = permitted?("shipment_documents", "approve")
  def waive?   = permitted?("shipment_documents", "waive")

  class Scope < ApplicationPolicy::Scope
    def resolve = organization_scope
  end
end
