require 'rails_helper'

RSpec.describe Api::V1::GogovanTransportsController, type: :controller do
  let(:reviewer) { create(:user, :reviewer) }
  let(:gogovan_transport) { create(:gogovan_transport, name_en: "Van") }
  let(:parsed_body) { JSON.parse(response.body) }

  describe "GET gogovan_transport" do
    
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
      expect(parsed_body['gogovan_transports'].length).to eq(1)
      expect(parsed_body['gogovan_transports'][0]['name']).to eq(gogovan_transport.name)
      expect(parsed_body['gogovan_transports'][0]['disabled']).to eq(gogovan_transport.disabled)
    end
  end
end
