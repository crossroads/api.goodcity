module Api
  module V1
    class PackageSetsController < Api::V1::ApiController
      load_and_authorize_resource :package_set, parent: false

      resource_description do
        short 'Get, create, update and delete package_sets.'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :package_set do
        param :package_set, Hash, required: true do
          param :description, String, allow_nil: true, desc: "Description/Details of the set"
          param :package_type_id, String, allow_nil: true, desc: "The type of packages contained in the set"
        end
      end

      api :GET, '/v1/package_sets', "Get a package set"
      def show
        render json: @package_set, serializer: serializer
      end

      api :POST, '/v1/package_sets', "Create a package set"
      param_group :package_set
      def create
        if @package_set.save
          render json: @package_set, serializer: serializer, status: 201
        else
          render json: @package_set.errors, status: 422
        end
      end

      api :PUT, '/v1/package_sets/1', "Update an package_set_id"
      param_group :package_set
      def update
        @package_set.assign_attributes(package_set_params)
        if @package_set.valid? && @package_set.save
          render json: @package_set, serializer: serializer
        else
          render_error(@package_set.errors.full_messages.join(". "))
        end
      end

      api :DELETE, '/v1/package_sets/1', "Delete a package_set"
      description "The set's packages will have their package_set_id field nulled"
      def destroy
        @package_set.destroy!
        render json: {}
      end

      private

      def serializer
        is_stock_app? ? Api::V1::PackageSetSerializer::StockFormat : Api::V1::PackageSetSerializer
      end

      def package_set_params
        params.require(:package_set).permit(:description, :package_type_id)
      end
    end
  end
end