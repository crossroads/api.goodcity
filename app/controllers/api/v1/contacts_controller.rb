module Api::V1
  class ContactsController < Api::V1::ApiController

    load_and_authorize_resource :contact, parent: false

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
