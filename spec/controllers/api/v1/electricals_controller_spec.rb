require 'rails_helper'

RSpec.describe Api::V1::ElectricalsController, type: :controller do
  let(:user) { create(:user, :with_token, :with_can_manage_package_detail_permission, role_name: 'Order Fulfilment') }
  let(:electrical_params) { FactoryBot.attributes_for(:electrical) }

  before do
    generate_and_set_token(user)
    @electrical = build(:electrical)
    @electrical.save
    serialized_electrical_with_country = Api::V1::ElectricalSerializer.new(@electrical, include_country: true).as_json
    @parsed_body_with_country = JSON.parse( serialized_electrical_with_country.to_json )

    serialized_electrical_without_country = Api::V1::ElectricalSerializer.new(@electrical, include_country: true).as_json
    @parsed_body_without_country = JSON.parse( serialized_electrical_without_country.to_json )
  end

  describe "GET electricals" do
    it "returns 200", :show_in_doc do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized electricals" do
      get :index
      body = JSON.parse(response.body)
      expect(body['electricals'].length).to eq(Electrical.count)
    end
  end

  describe "Get electrical" do
    it "returns 200", :show_in_doc do
      get :show, params: { id: @electrical.id }
      expect(response.status).to eq(200)
    end

    it "return serialized electrical", :show_in_doc do
      get :show, params: { id: @electrical.id }
      expect(@parsed_body_with_country).to eq(JSON.parse(response.body))
    end
  end

  describe "PUT update" do
    it "returns 200" do
      put :update, params: { id: @electrical.id, :electrical => { brand: "Havells" } }
      expect(response.status).to eq(200)
      expect(@electrical.reload.brand).to eq("havells")
    end
  end

  describe "DELETE destroy" do
    it "returns 200" do
      delete :destroy, params: { id: @electrical.id }
      expect(response.status).to eq(200)
    end
  end
end
