class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  allow_browser versions: :modern

  set_current_tenant_through_filter
  before_action :set_tenant_from_path
  before_action :require_org_membership

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

    def current_user
      Current.user
    end

    def set_tenant_from_path
      return if params[:org_slug].blank?

      org = Organization.find_by(subdomain: params[:org_slug])
      return redirect_to new_login_path(org_slug: params[:org_slug]), alert: "Organization not found." unless org

      set_current_tenant(org)
      Current.organization = org
    end

    def require_org_membership
      return unless Current.user
      return unless Current.organization

      unless Current.user.organization_id == Current.organization.id
        terminate_session
        redirect_to new_login_path(org_slug: params[:org_slug]), alert: "You are not a member of this organization."
      end
    end

    def user_not_authorized
      redirect_back_or_to root_path, alert: "You are not authorized to perform this action."
    end
end
