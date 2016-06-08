module Api::V1
  class StockitContactsController < Api::V1::ApiController

    skip_before_action :validate_token, only: [:create]
    load_and_authorize_resource :stockit_contact, parent: false

    resource_description do
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    def_param_group :stockit_contact do
      param :stockit_contact, Hash, required: true do
        param :name, String, desc: "Name of organisation"
        param :stockit_id, String, desc: "stockit organisation record id"
      end
    end

    api :POST, "/v1/stockit_contacts", "Create or Update a stockit_contact"
    param_group :stockit_contact
    def create
      if stockit_contact_record.save
        render json: @stockit_contact, serializer: serializer, status: 201
      else
        render json: @stockit_contact.errors.to_json, status: 422
      end
    end

    private

    def stockit_contact_record
      @stockit_contact = StockitContact.where(stockit_id: stockit_contact_params[:stockit_id]).first_or_initialize
      @stockit_contact.assign_attributes(stockit_contact_params)
      @stockit_contact
    end

    def stockit_contact_params
      params.require(:stockit_contact).permit(:stockit_id, :first_name,
        :last_name, :mobile_phone_number, :phone_number)
    end

    def serializer
      Api::V1::StockitContactSerializer
    end

  end
end
