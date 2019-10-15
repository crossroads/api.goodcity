require 'rails_helper'

RSpec.describe Api::V1::ComputerAccessoriesController, type: :controller do

  let(:user) { create(:user_with_token, :with_can_read_or_modify_user_permission, role_name: 'Reviewer') }
  let(:computer_accessory_params) { FactoryBot.attributes_for(:computer_accessory) }

  before do
    generate_and_set_token(user)
    @computer_accessory = build(:computer_accessory)
    allow(Stockit::ItemDetailSync).to receive(:create).with(@computer_accessory).and_return({"status"=>201, "computer_accessory_id"=> 12})
    @computer_accessory.save
    serialized_computer_accessory = Api::V1::ComputerAccessorySerializer.new(@computer_accessory).as_json
    @parsed_body = JSON.parse( serialized_computer_accessory.to_json )
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
      get :show, id: @computer_accessory.id
      expect(response.status).to eq(200)
    end

    it "return serialized address", :show_in_doc do
      get :show, id: @computer_accessory.id
      expect(@parsed_body).to eq(JSON.parse(response.body))
    end
  end

  describe "PUT update" do
    it "returns 200" do
      allow(Stockit::ItemDetailSync).to receive(:update).with(@computer_accessory).and_return({"status"=>201, "computer_accessory_id"=> 12})
      put :update, id: @computer_accessory.id, :computer_accessory => { brand: "lenovo" }
      expect(response.status).to eq(200)
      expect(@computer_accessory.reload.brand).to eq("lenovo")
    end
  end
end
