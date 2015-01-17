require 'rails_helper'

RSpec.describe Api::V1::GogovanTransportsController, type: :controller do
  let(:reviewer) { create(:user, :reviewer) }

  describe "GET gogovan_transport" do
    let!(:gogovan_transport1) { create(:gogovan_transport, name_en: "Van") }
    let!(:gogovan_transport2) { create(:gogovan_transport, name_en: "5.5t Truck") }
    before { generate_and_set_token(reviewer) }

    it "returns 200", :show_in_doc do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized gogovan_transport" do
      get :index
      body = JSON.parse(response.body)
      expect(body['gogovan_transports'].length).to eq(2)
    end
  end
end
