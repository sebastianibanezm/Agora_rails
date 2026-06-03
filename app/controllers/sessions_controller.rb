class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_login_path(org_slug: params[:org_slug]), alert: "Try again later." }

  def new
    render inertia: "Login", props: {
      org_name: Current.organization&.name,
      org_slug: params[:org_slug],
      flash: flash.to_h
    }
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      destination = tenant_root_url(user)
      if request.inertia?
        inertia_location destination
      else
        redirect_to destination
      end
    else
      redirect_to(params[:org_slug] ? new_login_path(org_slug: params[:org_slug]) : new_admin_login_path, alert: "Invalid email or password.")
    end
  end

  def destroy
    org_slug = Current.user&.organization&.subdomain
    terminate_session
    if org_slug
      redirect_to new_login_path(org_slug: org_slug), status: :see_other
    else
      redirect_to new_admin_login_path, status: :see_other
    end
  end
end
