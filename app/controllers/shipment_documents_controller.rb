class ShipmentDocumentsController < ApplicationController
  before_action :set_shipment_document

  def update
    authorize @shipment_document

    ActiveRecord::Base.transaction do
      @shipment_document.update!(shipment_document_params)
      update_field_values
      RecalculateShipmentDocumentStatus.call!(@shipment_document)
    end
    redirect_back fallback_location: shipment_path(org_slug: params[:org_slug], id: @shipment_document.shipment), notice: "Documento actualizado."
  end

  def approve
    authorize @shipment_document, :approve?

    ActiveRecord::Base.transaction do
      @shipment_document.update!(status: "approved", completed_at: Time.current)
      RecalculateShipmentDocumentStatus.call!(@shipment_document)
    end
    redirect_back fallback_location: shipment_path(org_slug: params[:org_slug], id: @shipment_document.shipment), notice: "Documento aprobado."
  end

  def waive
    authorize @shipment_document, :waive?

    ActiveRecord::Base.transaction do
      @shipment_document.update!(
        status: "waived",
        waiver_reason: params[:waiver_reason].presence || "Excepcion operacional",
        completed_at: Time.current
      )
      RecalculateShipmentDocumentStatus.call!(@shipment_document)
    end
    redirect_back fallback_location: shipment_path(org_slug: params[:org_slug], id: @shipment_document.shipment), notice: "Documento eximido."
  end

  private

    def set_shipment_document
      @shipment_document = Current.organization.shipment_documents.find(params[:id])
    end

    def shipment_document_params
      params.require(:shipment_document).permit(:status)
    end

    def update_field_values
      Array(params[:field_values]).each do |field_attrs|
        field_value = @shipment_document.shipment_document_field_values.find(field_attrs[:id])
        field_value.update!(
          raw_value: field_attrs[:raw_value],
          value: field_attrs[:raw_value].presence,
          source: "manual",
          confirmed: ActiveModel::Type::Boolean.new.cast(field_attrs[:confirmed])
        )
      end
    end
end
