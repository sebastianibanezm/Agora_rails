class ValidateShipmentSourceOfTruth
  def self.call(shipment)
    ServiceResult.capture { call!(shipment) }
  end

  def self.call!(shipment)
    new(shipment).call
  end

  def initialize(shipment)
    @shipment = shipment
    @organization = shipment.organization
  end

  def call
    ActsAsTenant.with_tenant(organization) do
      organization.source_of_truth_rules.includes(:source_of_truth_rule_targets, :document_field_definition).find_each do |rule|
        authoritative_documents = shipment.workflow_documents.where(document_template: rule.authoritative_document_template)
        next if authoritative_documents.blank?

        rule.source_of_truth_rule_targets.each do |target|
          target_documents = shipment.workflow_documents.where(document_template: target.document_template)
          authoritative_documents.each do |authoritative_document|
            target_documents.each do |target_document|
              next if authoritative_document.id == target_document.id

              persist_check(rule, authoritative_document, target_document)
            end
          end
        end
      end
    end
  end

  private

    attr_reader :shipment, :organization

    def persist_check(rule, authoritative_document, target_document)
      expected_value = field_value(authoritative_document, rule.document_field_definition)
      actual_value = field_value(target_document, rule.document_field_definition)
      status = expected_value == actual_value ? "matched" : "mismatch"

      check = organization.source_of_truth_checks.find_or_initialize_by(
        shipment: shipment,
        source_of_truth_rule: rule,
        authoritative_shipment_document: authoritative_document,
        target_shipment_document: target_document
      )
      check.update!(
        document_field_definition: rule.document_field_definition,
        status: status,
        expected_value: expected_value,
        actual_value: actual_value,
        failure_action: rule.failure_action
      )
    end

    def field_value(document, field)
      document.shipment_document_field_values.find_by(document_field_definition: field)&.value
    end
end
