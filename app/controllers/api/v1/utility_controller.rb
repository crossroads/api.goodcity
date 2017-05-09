module Api::V1
  class UtilityController < ApplicationController
    def assign_params_and_render_object(data_object, serializer, params={})
      data_object.attributes = params
      if data_object.save
        render json: data_object, serializer: serializer, status: 201
      else
        render json: data_object.errors.to_json, status: 422
      end
    end

    def render_object(data_object, model_name, serializer, params)
      if params[:ids].blank?
        render json: model_name.cached_json
        return
      end
      data_object = data_object.find( params[:ids].split(",") ) if params[:ids].present?
      render json: data_object, each_serializer: serializer
    end
  end
end
