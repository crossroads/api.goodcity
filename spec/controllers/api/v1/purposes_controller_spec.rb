require 'rails_helper'

RSpec.describe Api::V1::PurposesController, type: :controller do
  let(:reviewer) { create(:user, :reviewer) }
  let(:purpose) { create(:purpose) }
  let(:parsed_body) { JSON.parse(response.body) }

  describe "GET purpose" do
    before { generate_and_set_token(reviewer) }

    it "returns 200", :show_in_doc do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized purpose" do
      purpose
      get :index
      expect(parsed_body['purposes'].length).to eq(1)
      expect(parsed_body['purposes'][0]['name_en']).to eq(purpose.name_en)
    end
  end
end
