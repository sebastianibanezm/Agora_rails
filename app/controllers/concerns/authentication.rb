module Authentication
  extend ActiveSupport::Concern

  SESSION_COOKIE_EXPIRES_IN = 2.weeks

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      org_slug = params[:org_slug] || Current.user&.organization&.subdomain
      redirect_to new_login_path(org_slug: org_slug)
    end

    def tenant_root_url(user)
      org = Current.organization || user.organization
      return avo.root_url unless org
      main_app.org_root_url(org_slug: org.subdomain)
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed[:session_id] = {
          value: session.id,
          httponly: true,
          same_site: :lax,
          expires: SESSION_COOKIE_EXPIRES_IN.from_now
        }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
