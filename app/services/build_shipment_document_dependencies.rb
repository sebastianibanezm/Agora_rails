class BuildShipmentDocumentDependencies
  def self.call(shipment)
    new(shipment).call
  end

  def initialize(shipment)
    @shipment = shipment
    @organization = shipment.organization
  end

  def call
    ActsAsTenant.with_tenant(organization) do
      organization.document_template_dependencies.includes(:prerequisite_document_template, :dependent_document_template).find_each do |template_dependency|
        prerequisite_documents = documents_for(template_dependency.prerequisite_document_template)
        dependent_documents = documents_for(template_dependency.dependent_document_template)

        dependent_documents.each do |dependent_document|
          prerequisite_documents.each do |prerequisite_document|
            next if dependent_document.id == prerequisite_document.id

            dependency = find_or_create_dependency(dependent_document, prerequisite_document)
            dependency.status = prerequisite_document.approved_or_waived? ? "satisfied" : "open" unless dependency.status == "waived"
            dependency.save!
          end
        end
      end
    end
  end

  private

    attr_reader :shipment, :organization

    def documents_for(template)
      shipment.shipment_documents.where(document_template: template).to_a
    end

    def find_or_create_dependency(dependent_document, prerequisite_document)
      attributes = {
        shipment_document: dependent_document,
        prerequisite_shipment_document: prerequisite_document
      }

      organization.shipment_document_dependencies.find_by(attributes) ||
        organization.shipment_document_dependencies.create!(attributes)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => error
      organization.shipment_document_dependencies.find_by(attributes) || raise(error)
    end
end
