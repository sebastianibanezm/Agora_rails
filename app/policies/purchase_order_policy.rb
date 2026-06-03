class PurchaseOrderPolicy < ApplicationPolicy
  def index?   = permitted?("purchase_orders", "view")
  def show?    = permitted?("purchase_orders", "view")
  def new?     = permitted?("purchase_orders", "create")
  def create?  = permitted?("purchase_orders", "create")
  def edit?    = permitted?("purchase_orders", "update")
  def update?  = permitted?("purchase_orders", "update")
  def destroy? = permitted?("purchase_orders", "destroy")

  class Scope < ApplicationPolicy::Scope
    def resolve = organization_scope
  end
end
