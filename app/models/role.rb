class Role < ApplicationRecord
  belongs_to :organization
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions
  has_many :users

  validates :name, presence: true, uniqueness: { scope: :organization_id }

  def can?(resource, action)
    permissions.exists?(resource: resource, action: action.to_s)
  end
end
