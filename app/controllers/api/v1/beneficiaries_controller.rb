module Api
  module V1
    class BeneficiariesController < Api::V1::ApiController
      load_and_authorize_resource :beneficiary, parent: false

      resource_description do
        short 'Manage a list of beneficiaries.'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def self.build_param_group(strict: true)
        param :beneficiary, Hash, required: true do
          param :identity_type_id, :number, required: strict
          param :identity_number, String, required: strict
          param :title, String, required: strict
          param :first_name, String, required: strict
          param :last_name, String, required: strict
          param :phone_number, String, required: strict
        end
      end

      def_param_group(:beneficiary_strict) { build_param_group(strict: true) }
      def_param_group(:beneficiary) { build_param_group(strict: false) }

      def beneficiary_params
        attributes = [:identity_type_id, :identity_number, :title, :first_name, :last_name, :phone_number]
        params.require(:beneficiary).permit(attributes)
      end

      api :GET, '/v1/beneficiaries', "List all beneficiaries"
      def index
        render json: @beneficiaries, each_serializer: serializer, status: 200
      end

      api :GET, '/v1/beneficiaries/1', "Get one beneficiary"
      def show
        render json: @beneficiary, serializer: serializer
      end

      api :POST, "/v1/beneficiaries", "Create a beneficiary"
      param_group :beneficiary_strict
      def create
        @beneficiary.order = Order.find_by_id(params['order_id'])
        @beneficiary.created_by = current_user
        save_and_render_object(@beneficiary)
      end

      api :PUT, '/v1/beneficiaries/1', "Update user"
      param_group :beneficiary
      def update
        if @beneficiary.update_attributes(beneficiary_params)
          render json: @beneficiary, serializer: serializer
        else
          render json: { errors: @beneficiary.errors.full_messages }, status: 422
        end
      end

      api :DELETE, '/v1/beneficiary/1', "Delete a beneficiary"
      def destroy
        @beneficiary.destroy
        render json: {}
      end

      def serializer
        Api::V1::BeneficiarySerializer
      end
    end
  end
end
