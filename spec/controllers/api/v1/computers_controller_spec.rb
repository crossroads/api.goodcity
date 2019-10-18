require 'rails_helper'

RSpec.describe Api::V1::ComputersController, type: :controller do

  let(:user) { create(:user_with_token, :with_can_read_or_modify_user_permission, role_name: 'Reviewer') }
  let(:computer_params) { FactoryBot.attributes_for(:computer) }

  before do
    generate_and_set_token(user)
    @computer = build(:computer)
    allow(Stockit::ItemDetailSync).to receive(:create).with(@computer).and_return({"status"=>201, "computer_id"=> 12})
    @computer.save
    serialized_computer_with_country = Api::V1::ComputerSerializer.new(@computer, include_country: true).as_json
    @parsed_body_with_country = JSON.parse( serialized_computer_with_country.to_json )

    serialized_computer_without_country = Api::V1::ComputerSerializer.new(@computer, include_country: true).as_json
    @parsed_body_without_country = JSON.parse( serialized_computer_without_country.to_json )
  end

  describe "GET computers" do
    it "returns 200", :show_in_doc do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized computers" do
      get :index
      body = JSON.parse(response.body)
      expect( body['computers'].length ).to eq(Computer.count)
    end
  end

  describe "Get computer" do
    it "returns 200", :show_in_doc do
      get :show, id: @computer.id
      expect(response.status).to eq(200)
    end

    it "returns correct record", :show_in_doc do
      get :show, id: @computer.id
      expect(@parsed_body_with_country).to eq(JSON.parse(response.body))
    end
  end

  describe "PUT update" do
    it "returns 200" do
      allow(Stockit::ItemDetailSync).to receive(:update).with(@computer).and_return({"status"=>201, "computer_id"=> 12})
      put :update, id: @computer.id, :computer => { brand: "lenovo" }
      expect(response.status).to eq(200)
      expect(@computer.reload.brand).to eq("lenovo")
    end
  end
end
