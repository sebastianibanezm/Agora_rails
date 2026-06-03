class TradingPartnerPolicy < ApplicationPolicy
  def index?   = permitted?("trading_partners", "view")
  def show?    = permitted?("trading_partners", "view")
  def new?     = permitted?("trading_partners", "create")
  def create?  = permitted?("trading_partners", "create")
  def edit?    = permitted?("trading_partners", "update")
  def update?  = permitted?("trading_partners", "update")
  def destroy? = permitted?("trading_partners", "destroy")

  class Scope < ApplicationPolicy::Scope
    def resolve = organization_scope
  end
end
