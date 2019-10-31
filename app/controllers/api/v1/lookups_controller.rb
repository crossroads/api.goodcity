module Api
  module V1
    class LookupsController < Api::V1::ApiController
      skip_authorization_check only: :index

      def index
        render json: Lookup.all, each_serializer: Api::V1::LookupSerializer
      end
    end
  end
end
