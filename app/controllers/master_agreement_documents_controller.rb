class MasterAgreementDocumentsController < ApplicationController
  before_action :set_master_agreement
  before_action :set_master_agreement_document, only: %i[extract review]

  def create
    authorize @master_agreement, :update?

    document = Current.organization.master_agreement_documents.create!(
      master_agreement: @master_agreement,
      title: document_params[:title].presence || document_params[:file]&.original_filename || "Contract document",
      document_kind: document_params[:document_kind].presence || "agreement",
      effective_on: document_params[:effective_on],
      expires_on: document_params[:expires_on],
      extraction_status: "pending"
    )
    document.file.attach(document_params[:file]) if document_params[:file].present?
    MasterAgreementExtractionJob.perform_later(document) if ActiveModel::Type::Boolean.new.cast(params[:extract])

    redirect_to master_agreement_path(org_slug: params[:org_slug], id: @master_agreement), notice: "Contract document uploaded."
  end

  def extract
    authorize @master_agreement, :update?

    @master_agreement_document.update!(extraction_status: "pending", extraction_error: nil)
    MasterAgreementExtractionJob.perform_later(@master_agreement_document)

    redirect_to master_agreement_path(org_slug: params[:org_slug], id: @master_agreement), notice: "Extraction queued."
  end

  def review
    authorize @master_agreement, :update?

    review_status = params.fetch(:review_status, "confirmed")
    raise ArgumentError, "Unsupported review status" unless review_status.in?(MasterAgreementExtractionRecord::REVIEW_STATUSES)

    ActiveRecord::Base.transaction do
      review_records(@master_agreement_document, review_status)
      @master_agreement_document.update!(reviewed_at: Time.current, reviewed_by: Current.user)
      ContractExtraction::SyncReviewedValues.call!(@master_agreement)
    end

    redirect_to master_agreement_path(org_slug: params[:org_slug], id: @master_agreement), notice: "Contract extraction reviewed."
  end

  private

    def set_master_agreement
      @master_agreement = Current.organization.master_agreements.find(params[:master_agreement_id])
    end

    def set_master_agreement_document
      @master_agreement_document = @master_agreement.master_agreement_documents.find(params[:id])
    end

    def document_params
      params.require(:master_agreement_document).permit(:title, :document_kind, :effective_on, :expires_on, :file)
    end

    def review_records(document, review_status)
      attrs = { review_status: review_status, updated_at: Time.current }
      document.master_agreement_extracted_values.update_all(attrs.merge(reviewed_at: Time.current, reviewed_by_id: Current.user&.id))
      document.master_agreement_parties.update_all(attrs)
      document.master_agreement_contacts.update_all(attrs)
      document.master_agreement_signers.update_all(attrs)
      document.master_agreement_schedules.update_all(attrs)
      document.master_agreement_clauses.update_all(attrs)

      schedule_ids = document.master_agreement_schedules.pluck(:id)
      return if schedule_ids.blank?

      Current.organization.master_agreement_delivery_locations.where(master_agreement_schedule_id: schedule_ids).update_all(attrs)
      Current.organization.master_agreement_product_price_lines.where(master_agreement_schedule_id: schedule_ids).update_all(attrs)
    end
end
