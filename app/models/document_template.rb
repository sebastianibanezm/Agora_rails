class DocumentTemplate < ApplicationRecord
  DOCUMENT_TYPES = %w[master derivado externo regulatorio cuadratura_fisica operacional].freeze
  CATEGORIES = %w[documento artefacto set].freeze
  OBLIGATIONS = %w[obligatorio recomendado condicional].freeze
  CRITICALITIES = %w[critico alto medio bajo informativo].freeze
  GRAINS = %w[relacion_comercial sku_producto po lote embarque contenedor set_documentario].freeze

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :workflow_phase

  has_many :outgoing_dependencies,
           class_name: "DocumentTemplateDependency",
           foreign_key: :prerequisite_document_template_id,
           inverse_of: :prerequisite_document_template,
           dependent: :destroy
  has_many :incoming_dependencies,
           class_name: "DocumentTemplateDependency",
           foreign_key: :dependent_document_template_id,
           inverse_of: :dependent_document_template,
           dependent: :destroy
  has_many :prerequisite_document_templates, through: :incoming_dependencies
  has_many :dependent_document_templates, through: :outgoing_dependencies

  has_many :document_template_fields, dependent: :destroy
  has_many :document_field_definitions, through: :document_template_fields
  has_many :shipment_documents, dependent: :restrict_with_error
  has_many :source_of_truth_rules,
           foreign_key: :authoritative_document_template_id,
           inverse_of: :authoritative_document_template,
           dependent: :restrict_with_error
  has_many :source_of_truth_rule_targets, dependent: :destroy

  has_paper_trail

  validates :code, presence: true, uniqueness: { scope: :organization_id },
                   format: { with: /\A[a-z0-9_]+\z/, message: "only lowercase letters, numbers, and underscores" }
  validates :name, :document_type, :category, :obligation, :criticality, :grain, presence: true
  validates :step_number, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :document_type, inclusion: { in: DOCUMENT_TYPES }
  validates :category, inclusion: { in: CATEGORIES }
  validates :obligation, inclusion: { in: OBLIGATIONS }
  validates :criticality, inclusion: { in: CRITICALITIES }
  validates :grain, inclusion: { in: GRAINS }
  validate :workflow_phase_belongs_to_organization

  private

    def workflow_phase_belongs_to_organization
      return if workflow_phase.blank? || organization_id.blank?
      return if workflow_phase.organization_id == organization_id

      errors.add(:workflow_phase, "must belong to the same organization")
    end
end
