require 'rails_helper'

RSpec.describe Api::V1::GogovanTransportTypesController, type: :controller do
  describe "GET gogovan_transport_types" do
    it "returns 200", :show_in_doc do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized gogovan_transport_types" do
      get :index
      body = JSON.parse(response.body)
      expect( body['gogovan_transport_types'].length ).to eq(3)
    end
  end
end
