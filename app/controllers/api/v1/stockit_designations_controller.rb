module Api::V1
  class StockitDesignationsController < Api::V1::ApiController

    load_and_authorize_resource :stockit_designation, parent: false
    before_action :eager_load_designation, only: :show

    resource_description do
      short 'Retrieve a list of designations, information about stock items that have been designated to a group or person.'
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

    api :GET, '/v1/stockit_designations', "List all stockit_designations"
    def index
      return recent_designations if params['recently_used'].present?
      records = @stockit_designations.with_eager_load.
        search(params['searchText']).latest.
        page(params["page"]).per(params["per_page"])
      stockit_designations = ActiveModel::ArraySerializer.new(records, each_serializer: serializer, root: "designations", exclude_stockit_set_item: true).to_json
      render json: stockit_designations.chop + ",\"meta\":{\"total_pages\": #{records.total_pages}, \"search\": \"#{params['searchText']}\"}}"
    end

    api :GET, '/v1/designations/1', "Get a stockit_designation"
    def show
      render json: @stockit_designation, serializer: serializer, root: "designation", exclude_code_details: true
    end

    def recent_designations
      records = StockitDesignation.recently_used(User.current_user.id)
      stockit_designations = ActiveModel::ArraySerializer.new(records, each_serializer: serializer, root: "designations").to_json
      render json: stockit_designations
    end

    private

    def stockit_designation_record
      @stockit_designation = StockitDesignation.where(stockit_id: stockit_designation_params[:stockit_id]).first_or_initialize
      @stockit_designation.assign_attributes(stockit_designation_params)
      @stockit_designation.stockit_activity = stockit_activity
      @stockit_designation.stockit_contact = stockit_contact
      @stockit_designation.stockit_organisation = stockit_organisation
      @stockit_designation.detail = stockit_local_order
      @stockit_designation
    end

    def stockit_designation_params
      params.require(:stockit_designation).permit(:stockit_id, :code, :status, :created_at, :stockit_contact_id, :detail_id, :detail_type, :stockit_organisation_id, :description, :stockit_activity_id)
    end

    def serializer
      Api::V1::StockitDesignationSerializer
    end

    def stockit_activity
      StockitActivity.find_by(stockit_id: params["stockit_designation"]["stockit_activity_id"])
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

    def eager_load_designation
      @stockit_designation = StockitDesignation.with_eager_load.find(params[:id])
    end

  end
end
