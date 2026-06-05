class Organization < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :trading_partners, dependent: :destroy
  has_many :master_agreements, dependent: :destroy
  has_many :purchase_orders, dependent: :destroy
  has_many :purchase_order_lines, dependent: :destroy
  has_many :shipments, dependent: :destroy
  has_many :shipment_lots, dependent: :destroy
  has_many :shipment_containers, dependent: :destroy
  has_many :shipment_documents, dependent: :destroy
  has_many :shipment_document_field_values, dependent: :destroy
  has_many :shipment_document_dependencies, dependent: :destroy
  has_many :source_of_truth_checks, dependent: :destroy
  has_many :document_template_dependencies, dependent: :destroy
  has_many :document_template_fields, dependent: :destroy
  has_many :source_of_truth_rule_targets, dependent: :destroy
  has_many :source_of_truth_rules, dependent: :destroy
  has_many :document_templates, dependent: :destroy
  has_many :document_field_definitions, dependent: :destroy
  has_many :workflow_phases, dependent: :destroy
  has_many :master_agreement_documents, dependent: :destroy
  has_many :master_agreement_extracted_values, dependent: :destroy
  has_many :master_agreement_parties, dependent: :destroy
  has_many :master_agreement_contacts, dependent: :destroy
  has_many :master_agreement_signers, dependent: :destroy
  has_many :master_agreement_schedules, dependent: :destroy
  has_many :master_agreement_delivery_locations, dependent: :destroy
  has_many :master_agreement_product_price_lines, dependent: :destroy
  has_many :master_agreement_clauses, dependent: :destroy

  has_paper_trail

  after_create :seed_roles
  after_create :seed_workflow_templates

  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9\-]+\z/, message: "only lowercase letters, numbers, and hyphens" }
  validates :plan, presence: true

  PLANS = %w[starter growth enterprise].freeze
  validates :plan, inclusion: { in: PLANS }

  def feature_enabled?(key)
    features[key.to_s] == true
  end

  private

    def seed_roles
      SeedOrganizationRoles.call(self)
    end

    def seed_workflow_templates
      SeedWorkflowTemplates.call(self)
    end
end
