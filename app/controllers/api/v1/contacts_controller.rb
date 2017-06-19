module Api::V1
  class ContactsController < Api::V1::ApiController

    load_and_authorize_resource :contact, parent: false

    resource_description do
      short 'Manage contact details for offer collection / delivery'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    def_param_group :contact do
      param :contact, Hash, required: true do
        param :name, String, desc: "Full name of contact"
        param :mobile, String, desc: "Contact mobile number"
      end
    end

    api :POST, '/v1/contacts', "Create a new contact"
    param_group :contact
    def create
      save_and_render_object(@contact)
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
