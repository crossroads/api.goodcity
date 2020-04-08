# frozen_string_literal: true

module Api
  module V1
    class MedicalController < Api::V1::ApiController
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
          param :serial_number, String, desc: 'Seriel number of the medical item'
          param :expiry_date, String, desc: 'Expiry date of the medical item'
        end
      end
    end
  end
end
