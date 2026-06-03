class MasterAgreementPolicy < ApplicationPolicy
  def index?   = permitted?("master_agreements", "view")
  def show?    = permitted?("master_agreements", "view")
  def new?     = permitted?("master_agreements", "create")
  def create?  = permitted?("master_agreements", "create")
  def edit?    = permitted?("master_agreements", "update")
  def update?  = permitted?("master_agreements", "update")
  def destroy? = permitted?("master_agreements", "destroy")

  class Scope < ApplicationPolicy::Scope
    def resolve = organization_scope
  end
end
