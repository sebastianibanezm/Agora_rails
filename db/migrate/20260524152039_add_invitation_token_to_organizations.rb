class AddInvitationTokenToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :invitation_token, :string
    add_index :organizations, :invitation_token, unique: true
    add_column :organizations, :invitation_token_expires_at, :datetime
  end
end
