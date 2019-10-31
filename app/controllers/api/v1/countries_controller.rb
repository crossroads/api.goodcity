module Api
  module V1
    class CountriesController < Api::V1::ApiController
      load_and_authorize_resource :country, parent: false

      def index
        @countries = @countries.search(params["searchText"])
          .page(page).per(per_page) if params["searchText"]
        render json: @countries, each_serializer: Api::V1::CountrySerializer
      end

      def create
        if country_record.save
          render json: {}, status: 201
        else
          render json: @country.errors, status: 422
        end
      end

      private

      def country_record
        @country =
          if (stockit_id = country_params[:stockit_id]).present?
            Country.where(stockit_id: stockit_id).first_or_initialize
          else
            @country
          end
        @country.assign_attributes(country_params)
        @country
      end

      def country_params
        params.require(:country).permit(:stockit_id, :name_en, :name_zh_tw)
      end
    end
  end
end
