require 'rails_helper'

RSpec.describe Api::V1::CrossroadsTransportsController, type: :controller do
  let(:reviewer) { create(:user, :reviewer) }

  describe "GET crossroads_transport" do
    let!(:crossroads_transports) { create_list(:crossroads_transport, 3) }
    before { generate_and_set_token(reviewer) }

    it "returns 200", :show_in_doc do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized crossroads_transport" do
      get :index
      body = JSON.parse(response.body)
      expect(body['crossroads_transports'].length).to eq(3)
    end
  end
end

