class SourceOfTruthRuleTarget < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :source_of_truth_rule
  belongs_to :document_template

  has_paper_trail

  validates :document_template_id, uniqueness: { scope: %i[organization_id source_of_truth_rule_id] }
  validate :records_belong_to_organization

  private

    def records_belong_to_organization
      [source_of_truth_rule, document_template].compact.each do |record|
        next if record.organization_id == organization_id

        errors.add(:base, "linked records must belong to the same organization")
      end
    end
end
