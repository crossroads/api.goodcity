module Api::V1
  class ContactsController < Api::V1::ApiController

    load_and_authorize_resource :contact, parent: false

    resource_description do
      short 'Create Contact'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    def_param_group :contact do
      param :contact, Hash, required: true do
        param :name, String, desc: "Full-Name of Person to be contacted to verify offer."
        param :mobile, String, desc: "Mobile of Person to be contacted to verify offer."
      end
    end

    api :POST, '/v1/contacts', "Create a contact"
    param_group :contact
    def create
      @contact.attributes = contact_params
      if @contact.save
        render json: @contact, serializer: serializer, status: 201
      else
        render json: @contact.errors.to_json, status: 500
      end
    end

    private

    def serializer
      Api::V1::ContactSerializer
    end

    def contact_params
      params.require(:contact).permit(:name, :mobile)
    end

  end
end
