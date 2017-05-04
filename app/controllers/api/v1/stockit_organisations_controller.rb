module Api::V1
  class StockitOrganisationsController < Api::V1::ApiController

    load_and_authorize_resource :stockit_organisation, parent: false

    resource_description do
      resource_description_errors
    end

    def_param_group :stockit_organisation do
      param :stockit_organisation, Hash, required: true do
        param :name, String, desc: "Name of organisation"
        param :stockit_id, String, desc: "stockit organisation record id"
      end
    end

    api :POST, "/v1/stockit_organisations", "Create or Update a stockit_organisation"
    param_group :stockit_organisation
    def create
      if stockit_organisation_record.save
        render json: @stockit_organisation, serializer: serializer, status: 201
      else
        render json: @stockit_organisation.errors.to_json, status: 422
      end
    end

    private

    def stockit_organisation_record
      @stockit_organisation = StockitOrganisation.where(stockit_id: stockit_organisation_params[:stockit_id]).first_or_initialize
      @stockit_organisation.assign_attributes(stockit_organisation_params)
      @stockit_organisation
    end

    def stockit_organisation_params
      params.require(:stockit_organisation).permit(:stockit_id, :name)
    end

    def serializer
      Api::V1::StockitOrganisationSerializer
    end

  end
end
