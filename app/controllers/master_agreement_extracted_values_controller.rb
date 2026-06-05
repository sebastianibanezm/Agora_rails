class MasterAgreementExtractedValuesController < ApplicationController
  before_action :set_master_agreement
  before_action :set_extracted_value

  def update
    authorize @master_agreement, :update?

    @extracted_value.update!(extracted_value_params.merge(reviewed_at: Time.current, reviewed_by: Current.user))
    ContractExtraction::SyncReviewedValues.call!(@master_agreement) if @extracted_value.review_status.in?(%w[confirmed rejected])

    redirect_to master_agreement_path(org_slug: params[:org_slug], id: @master_agreement), notice: "Extracted value updated."
  end

  private

    def set_master_agreement
      @master_agreement = Current.organization.master_agreements.find(params[:master_agreement_id])
    end

    def set_extracted_value
      @extracted_value = @master_agreement.master_agreement_extracted_values.find(params[:id])
    end

    def extracted_value_params
      params.require(:master_agreement_extracted_value)
            .permit(:raw_value, :review_status, normalized_value: {})
    end
end
