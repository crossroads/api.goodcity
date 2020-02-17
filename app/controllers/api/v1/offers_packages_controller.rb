module Api
  module V1
    class OffersPackagesController < Api::V1::ApiController
      load_and_authorize_resource :offers_package, parent: false

      resource_description do
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :offers_packages do
        param :offers_packages, Hash, required: true do
          param :package_id, Integer, desc: "Id of package"
          param :offer_id, Integer, desc: "Id of offer"
        end
      end

      api :DELETE, '/v1/offers_package/1', "Delete an offers_package"
      def destroy
        if @offers_package
          @offers_package.destroy
        end
        render json: {}
      end

      private

      def offers_packages_params
        params.require(:offers_packages).permit(:package_id, :offer_id)
      end
    end
  end
end
