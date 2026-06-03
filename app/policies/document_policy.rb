class DocumentPolicy < ApplicationPolicy
  def index?   = permitted?("documents", "view")
  def show?    = permitted?("documents", "view")
  def new?     = permitted?("documents", "create")
  def create?  = permitted?("documents", "create")
  def edit?    = permitted?("documents", "update")
  def update?  = permitted?("documents", "update")
  def destroy? = permitted?("documents", "destroy")

  class Scope < ApplicationPolicy::Scope
    def resolve = organization_scope
  end
end
