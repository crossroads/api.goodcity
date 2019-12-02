require 'rails_helper'

RSpec.describe Api::V1::ComputerAccessoriesController, type: :controller do

  let(:user) { create(:user_with_token, :with_can_manage_package_detail_permission, role_name: 'Order Fulfilment') }
  let(:computer_accessory_params) { FactoryBot.attributes_for(:computer_accessory) }

  before do
    generate_and_set_token(user)
    @record = build(:computer_accessory)
    allow(Stockit::ItemDetailSync).to receive(:create).with(@record).and_return({"status"=>201, "computer_accessory_id"=> 12})
    @record.save

    serialized_record_with_country = Api::V1::ComputerAccessorySerializer.new(@record, include_country: true).as_json
    @parsed_body_with_country = JSON.parse( serialized_record_with_country.to_json )

    serialized_record_without_country = Api::V1::ComputerAccessorySerializer.new(@record, include_country: false).as_json
    @parsed_body_without_country = JSON.parse(serialized_record_without_country.to_json)
  end

  describe "GET computer_accessories" do
    it "returns 200", :show_in_doc do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized computer_accessories" do
      get :index
      body = JSON.parse(response.body)
      expect( body['computer_accessories'].length ).to eq(ComputerAccessory.count)
    end
  end

  describe "Get computer_accessory" do
    it "returns 200", :show_in_doc do
      get :show, id: @record.id
      expect(response.status).to eq(200)
    end

    it "return serialized address", :show_in_doc do
      get :show, id: @record.id
      expect(@parsed_body_with_country).to eq(JSON.parse(response.body))
    end
  end

  describe "PUT update" do
    it "returns 200" do
      allow(Stockit::ItemDetailSync).to receive(:update).with(@record).and_return({"status"=>201, "computer_accessory_id"=> 12})
      put :update, id: @record.id, :computer_accessory => { brand: "lenovo" }
      expect(response.status).to eq(200)
      expect(@record.reload.brand).to eq("lenovo")
    end
  end

  describe "DELETE destroy" do
    it "returns 200" do
      allow(Stockit::ItemDetailSync).to receive(:destroy).with(@record).and_return({"status"=>201})
      delete :destroy, id: @record.id
      expect(response.status).to eq(200)
    end
  end
end
