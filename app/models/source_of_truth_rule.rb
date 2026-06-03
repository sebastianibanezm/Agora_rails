class SourceOfTruthRule < ApplicationRecord
  FAILURE_ACTIONS = %w[correct_derivative change_lot reconcile_exception investigate_payment].freeze

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :document_field_definition
  belongs_to :authoritative_document_template, class_name: "DocumentTemplate"
  has_many :source_of_truth_rule_targets, dependent: :destroy
  has_many :document_templates, through: :source_of_truth_rule_targets
  has_many :source_of_truth_checks, dependent: :destroy

  has_paper_trail

  validates :logic, presence: true
  validates :failure_action, presence: true, inclusion: { in: FAILURE_ACTIONS }
  validates :document_field_definition_id,
            uniqueness: { scope: %i[organization_id authoritative_document_template_id] }
  validate :records_belong_to_organization
  validate :has_correction_target, unless: :new_record?

  private

    def records_belong_to_organization
      [document_field_definition, authoritative_document_template].compact.each do |record|
        next if record.organization_id == organization_id

        errors.add(:base, "linked records must belong to the same organization")
      end
    end

    def has_correction_target
      return if source_of_truth_rule_targets.exists?

      errors.add(:base, "must correct at least one target document")
    end
end
