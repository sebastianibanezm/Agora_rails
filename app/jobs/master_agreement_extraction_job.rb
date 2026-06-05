class MasterAgreementExtractionJob < ApplicationJob
  queue_as :default

  def perform(master_agreement_document)
    ContractExtraction::ExtractMasterAgreementDocument.call!(master_agreement_document)
  end
end
