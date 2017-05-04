module Api::V1
  class DistrictsController < Api::V1::ApiController

    skip_before_action :validate_token, only: [:index, :show]
    load_and_authorize_resource :district, parent: false

    resource_description do
      short 'Districts are sub-regions of Hong Kong territories'
      resource_description_errors
    end

    def_param_group :district do
      param :district, Hash, required: true do
        param :name, String, desc: "Name of District"
        param :territory_id, String, desc: "Id of territory to which district belongs."
      end
    end

    api :GET, '/v1/districts', "List all districts"
    param :ids, Array, of: Integer, desc: "Filter by district ids e.g. ids = [1,2,3,4]"
    def index
      render_object(@districts, District, params)
    end

    api :GET, '/v1/district/1', "List a district"
    def show
      render json: @district, serializer: serializer
    end

    private

    def serializer
      Api::V1::DistrictSerializer
    end

  end
end
