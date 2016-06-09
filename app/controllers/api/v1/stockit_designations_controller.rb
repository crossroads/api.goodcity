module Api::V1
  class StockitDesignationsController < Api::V1::ApiController

    skip_before_action :validate_token, only: [:create]
    load_and_authorize_resource :stockit_designation, parent: false

    resource_description do
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    def_param_group :stockit_designation do
      param :stockit_designation, Hash, required: true do
        param :status, String
        param :code, String
        param :created_at, String
        param :stockit_contact_id, String
        param :stockit_organisation_id, String
        param :detail_id, String
        param :stockit_id, String, desc: "stockit designation record id"
      end
    end

    api :POST, "/v1/stockit_designations", "Create or Update a stockit_designation"
    param_group :stockit_designation
    def create
      if stockit_designation_record.save
        render json: @stockit_designation, serializer: serializer, status: 201
      else
        render json: @stockit_designation.errors.to_json, status: 422
      end
    end

    private

    def stockit_designation_record
      @stockit_designation = StockitDesignation.where(stockit_id: stockit_designation_params[:stockit_id]).first_or_initialize
      @stockit_designation.assign_attributes(stockit_designation_params)
      @stockit_designation.stockit_contact = stockit_contact
      @stockit_designation.stockit_organisation = stockit_organisation
      @stockit_designation.detail = stockit_local_order
      @stockit_designation
    end

    def stockit_designation_params
      params.require(:stockit_designation).permit(:stockit_id, :code, :status, :created_at, :stockit_contact_id, :detail_id, :detail_type, :stockit_organisation_id)
    end

    def serializer
      Api::V1::StockitDesignationSerializer
    end

    def stockit_contact
      StockitContact.find_by(stockit_id: params["stockit_designation"]["stockit_contact_id"])
    end

    def stockit_organisation
      StockitOrganisation.find_by(stockit_id: params["stockit_designation"]["stockit_organisation_id"])
    end

    def stockit_local_order
      StockitLocalOrder.find_by(stockit_id: params["stockit_designation"]["detail_id"])
    end

  end
end
