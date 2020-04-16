# frozen_string_literal: true

module Api
  module V1
    # MedicalsController
    class MedicalsController < Api::V1::ApiController
      load_and_authorize_resource :medical, parent: false

      resource_description do
        short 'Create, update and show action to perform on Medical.'
        formats ['json']
        error 401, 'Unauthorized'
        error 404, 'Not found'
        error 422, 'Validation error'
        error 500, 'Internal server error'
      end

      def_param_group :medical do
        param :medical, Hash do
          param :brand, String, desc: 'Name of the brand'
          param :model, String, desc: 'Name of the model'
          param :serial_number, String, desc: 'Serial number of the medical item'
          param :country_id, Integer, desc: 'Country ID'
          param :updated_by_id, Integer, desc: 'ID of user who updated the record'
        end
      end

      api :GET, '/v1/medicals', 'Return all medical items'
      def index
        @medicals = @medicals.distinct_by_column(params["distinct"]) if params["distinct"]
        render json: @medicals, each_serializer: serializer
      end

      api :SHOW, '/v1/medicals/1', 'Return a medical item record'
      def show
        render json: @medical, serializer: serializer, include_country: true
      end

      api :UPDATE, '/v1/medicals/1', 'Updates a medical item record'
      param_group :medical
      def update
        @medical.assign_attributes(permitted_params)
        update_and_render_object_with_errors(@medical)
      end

      api :DELETE, '/v1/medicals/1', 'Deletes a medical item record'
      def destroy
        @medical.destroy
        render json: {}
      end

      private

      def permitted_params
        attributes = %i[
          brand country_id model serial_number
        ]
        params.require(:medical).permit(attributes)
      end

      def serializer
        Api::V1::MedicalSerializer
      end
    end
  end
end
