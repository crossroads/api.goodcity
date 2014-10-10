require 'rails_helper'

RSpec.describe Api::V1::DonorConditionsController, type: :controller do

  let(:user) { create(:user_with_token) }
  let(:donor_condition) { create(:donor_condition) }
  let(:serialized_donor_condition) { Api::V1::DonorConditionSerializer.new(donor_condition) }
  let(:serialized_donor_condition_json) { JSON.parse( serialized_donor_condition.to_json ) }

  describe "GET donor_condition" do
    before { generate_and_set_token(user) }
    it "returns 200" do
      get :show, id: donor_condition.id
      expect(response.status).to eq(200)
    end

    it "return serialized donor_condition", :show_in_doc do
      get :show, id: donor_condition.id
      body = JSON.parse(response.body)
      expect( body ).to eq(serialized_donor_condition_json)
    end
  end

  describe "GET donor_conditions" do
    let!(:donor_conditions) { create_list(:donor_condition, 4) }
    before { generate_and_set_token(user) }

    it "returns 200", :show_in_doc do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized donor_conditions" do
      get :index
      body = JSON.parse(response.body)
      expect( body['donor_conditions'].length ).to eq(DonorCondition.count)
    end
  end

end
