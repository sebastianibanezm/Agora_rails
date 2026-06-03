class WorkflowPhase < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  has_many :document_templates, dependent: :restrict_with_error

  has_paper_trail

  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 },
                       uniqueness: { scope: :organization_id }
  validates :code, presence: true, uniqueness: { scope: :organization_id },
                   format: { with: /\A[a-z0-9_]+\z/, message: "only lowercase letters, numbers, and underscores" }
  validates :name, presence: true
end
