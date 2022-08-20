require 'rails_helper'

RSpec.describe Api::V1::DonorConditionsController, type: :controller do
  let(:user) { create(:user, :with_token) }
  let(:donor_condition) { create(:donor_condition) }
  let(:serialized_donor_condition) { Api::V1::DonorConditionSerializer.new(donor_condition).as_json }
  let(:serialized_donor_condition_json) { JSON.parse( serialized_donor_condition.to_json ) }
  let(:parsed_body) { JSON.parse(response.body) }

  before { generate_and_set_token(user) }

  describe "GET donor_condition" do
    it "returns 200" do
      get :show, params: { id: donor_condition.id }
      expect(response.status).to eq(200)
    end

    it "return serialized donor_condition", :show_in_doc do
      get :show, params: { id: donor_condition.id }
      expect( parsed_body ).to eq(serialized_donor_condition_json)
    end
  end

  describe "GET donor_conditions" do
    before do
      2.times { create(:donor_condition) }
    end
    it "return serialized donor_conditions", :show_in_doc do
      get :index
      expect(response.status).to eq(200)
      expect( parsed_body['donor_conditions'].length ).to eq(2)
    end

    it "returns 'visible_to_donor' in serialized response" do
      get :index
      expect(response.status).to eq(200)
      expect( parsed_body['donor_conditions'].map { |condition| condition['visible_to_donor']} ).to eq(DonorCondition.pluck(:visible_to_donor))
    end
  end
end
