require 'rails_helper'

RSpec.describe Api::V1::AddressesController, type: :controller do

  let(:user) { create(:user_with_token) }
  let(:address) { create(:profile_address, addressable: user) }
  let(:serialized_address) { Api::V1::AddressSerializer.new(address).as_json }
  let(:serialized_address_json) { JSON.parse( serialized_address.to_json ) }
  let(:address_params) { FactoryGirl.attributes_for(:profile_address).merge({ addressable: user }) }
  let(:parsed_body) { JSON.parse(response.body) }

  describe "POST address/1" do
    before { generate_and_set_token(user) }
    it "returns 201", :show_in_doc do
      expect {
        post :create, address: address_params
      }.to change(Address, :count).by(1)
      expect(response.status).to eq(201)
    end
  end

  describe "GET address" do
    before do
      generate_and_set_token(user)
      get :show, id: address.id
    end
    it "returns 200" do
      expect(response.status).to eq(200)
    end
    it "return serialized address", :show_in_doc do
      expect(parsed_body).to eq(serialized_address_json)
    end
  end

end
