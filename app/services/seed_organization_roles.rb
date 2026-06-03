class SeedOrganizationRoles
  ROLE_PERMISSIONS = {
    "owner"  => -> { Permission.all },
    "admin"  => -> { Permission.where.not(resource: "members", action: %w[remove promote]) },
    "member" => -> { Permission.where(action: "view").or(Permission.where(resource: "documents", action: "create")) },
  }.freeze

  def self.call(organization)
    ROLE_PERMISSIONS.each do |role_name, scope_fn|
      role = organization.roles.find_or_create_by!(name: role_name)
      role.permissions = scope_fn.call
    end
  end
end
