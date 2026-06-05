class AddExpiryToSessions < ActiveRecord::Migration[8.1]
  def up
    add_column :sessions, :expires_at, :datetime
    execute <<~SQL.squish
      UPDATE sessions
      SET expires_at = CURRENT_TIMESTAMP + INTERVAL '14 days'
      WHERE expires_at IS NULL
    SQL
    change_column_null :sessions, :expires_at, false
    add_index :sessions, :expires_at
  end

  def down
    remove_index :sessions, :expires_at
    remove_column :sessions, :expires_at
  end
end
