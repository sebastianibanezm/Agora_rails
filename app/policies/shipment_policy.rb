class ShipmentPolicy < ApplicationPolicy
  def index?   = permitted?("shipments", "view")
  def show?    = permitted?("shipments", "view")
  def new?     = permitted?("shipments", "create")
  def create?  = permitted?("shipments", "create")
  def edit?    = permitted?("shipments", "update")
  def update?  = permitted?("shipments", "update")
  def destroy? = permitted?("shipments", "destroy")
  def validate_source_of_truth? = permitted?("shipments", "update")

  class Scope < ApplicationPolicy::Scope
    def resolve = organization_scope
  end
end
