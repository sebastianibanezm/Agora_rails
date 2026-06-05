class MasterAgreementProductPriceLinesController < ApplicationController
  before_action :set_master_agreement
  before_action :set_price_line

  def update
    authorize @master_agreement, :update?

    @price_line.update!(price_line_params)
    ContractExtraction::SyncReviewedValues.call!(@master_agreement) if @price_line.review_status.in?(%w[confirmed rejected])

    redirect_to master_agreement_path(org_slug: params[:org_slug], id: @master_agreement), notice: "Pricing row updated."
  end

  private

    def set_master_agreement
      @master_agreement = Current.organization.master_agreements.find(params[:master_agreement_id])
    end

    def set_price_line
      @price_line = @master_agreement.master_agreement_product_price_lines.find(params[:id])
    end

    def price_line_params
      params.require(:master_agreement_product_price_line)
            .permit(:participating_company, :product_description, :case_pack, :size, :uom, :unit_cost_delivered, :currency, :review_status)
    end
end
