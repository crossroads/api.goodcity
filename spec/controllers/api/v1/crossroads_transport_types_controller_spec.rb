require 'rails_helper'

RSpec.describe Api::V1::CrossroadsTransportTypesController, type: :controller do
  describe "GET crossroads_transport_types" do
    it "returns 200", :show_in_doc do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized crossroads_transport_types" do
      get :index
      body = JSON.parse(response.body)
      expect( body['crossroads_transport_types'].length ).to eq(8)
    end
  end
end
