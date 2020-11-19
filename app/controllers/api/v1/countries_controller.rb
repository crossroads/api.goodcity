module Api
  module V1
    class CountriesController < Api::V1::ApiController
      load_and_authorize_resource :country, parent: false

      def index
        if params["searchText"]
          @countries = @countries.search(params["searchText"])
                       .order(:name_en).page(page).per(per_page)
        end
        render json: @countries, each_serializer: Api::V1::CountrySerializer
      end

      def create
        @country.assign_attributes(country_params)
        if @country.save
          render json: {}, status: 201
        else
          render json: @country.errors, status: 422
        end
      end

      private

      def country_params
        params.require(:country).permit(:name_en, :name_zh_tw)
      end
    end
  end
end
