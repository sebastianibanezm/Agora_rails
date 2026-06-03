class DocumentFieldDefinition < ApplicationRecord
  VALUE_TYPES = %w[string text number decimal date datetime boolean weight money identifier].freeze

  acts_as_tenant :organization

  belongs_to :organization
  has_many :document_template_fields, dependent: :destroy
  has_many :document_templates, through: :document_template_fields
  has_many :source_of_truth_rules, dependent: :restrict_with_error
  has_many :shipment_document_field_values, dependent: :restrict_with_error
  has_many :source_of_truth_checks, dependent: :restrict_with_error

  has_paper_trail

  validates :key, presence: true, uniqueness: { scope: :organization_id },
                  format: { with: /\A[a-z0-9_]+\z/, message: "only lowercase letters, numbers, and underscores" }
  validates :name, :value_type, presence: true
  validates :value_type, inclusion: { in: VALUE_TYPES }
end
