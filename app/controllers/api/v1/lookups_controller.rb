module Api
  module V1
    class LookupsController < Api::V1::ApiController
      skip_authorization_check only: :index

      def index
        @lookups = Lookup.all
        @lookups = @lookups.where(name: params["name"]) if params["name"]
        render json: @lookups, each_serializer: Api::V1::LookupSerializer
      end
    end
  end
end
