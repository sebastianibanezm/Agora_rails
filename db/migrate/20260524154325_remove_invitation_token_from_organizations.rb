class RemoveInvitationTokenFromOrganizations < ActiveRecord::Migration[8.1]
  def change
    remove_column :organizations, :invitation_token, :string
    remove_column :organizations, :invitation_token_expires_at, :datetime
  end
end
