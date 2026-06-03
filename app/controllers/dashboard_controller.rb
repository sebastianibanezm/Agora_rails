class DashboardController < ApplicationController
  def index
    @organization = Current.organization
    @current_user = Current.user
    @users_count  = @organization.users.count
  end
end
