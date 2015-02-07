require 'rails_helper'

RSpec.describe Api::V1::GogovanTransportsController, type: :controller do
  let(:reviewer) { create(:user, :reviewer) }

  describe "GET gogovan_transport" do
    let(:gogovan_transport) { create(:gogovan_transport, name_en: "Van") }
    before { generate_and_set_token(reviewer) }

    it "returns 200", :show_in_doc do
      # Generate all transport options for listing in API docs
      generate(:gogovan_transports).keys.each do |name_en|
        create(:gogovan_transport, name_en: name_en)
      end
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized gogovan_transport" do
      gogovan_transport
      get :index
      body = JSON.parse(response.body)
      expect(body['gogovan_transports'].length).to eq(1)
      expect(body['gogovan_transports'][0]['name']).to eq(gogovan_transport.name)
    end
  end
end
