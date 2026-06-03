class DocumentTemplateDependency < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :prerequisite_document_template, class_name: "DocumentTemplate"
  belongs_to :dependent_document_template, class_name: "DocumentTemplate"

  has_paper_trail

  validates :prerequisite_document_template_id,
            uniqueness: { scope: %i[organization_id dependent_document_template_id] }
  validate :documents_belong_to_organization
  validate :cannot_depend_on_itself

  private

    def documents_belong_to_organization
      [prerequisite_document_template, dependent_document_template].compact.each do |document_template|
        next if document_template.organization_id == organization_id

        errors.add(:base, "document templates must belong to the same organization")
      end
    end

    def cannot_depend_on_itself
      return if prerequisite_document_template_id.blank? || dependent_document_template_id.blank?
      return unless prerequisite_document_template_id == dependent_document_template_id

      errors.add(:dependent_document_template, "cannot depend on itself")
    end
end
