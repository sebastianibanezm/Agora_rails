Avo.configure do |config|
  config.root_path = "/admin"
  config.app_name = "Agora Admin"

  config.current_user_method do
    Session.find_by(id: cookies.signed[:session_id])&.user
  end

  config.authenticate_with do
    user = Session.find_by(id: cookies.signed[:session_id])&.user
    unless user&.superadmin?
      redirect_to main_app.new_admin_login_path, alert: "Not authorized."
    end
  end
end
