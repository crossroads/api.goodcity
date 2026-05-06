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
      # Factory uses find_or_initialize_by(name_en: …); with seeded donor_conditions
      # bare create() often reuses rows instead of adding new ones.
      @extra_donor_conditions = 2.times.map do |i|
        create(
          :donor_condition,
          name_en: "RSpec extra donor condition #{i} #{SecureRandom.hex(4)}",
          name_zh_tw: "規格測試#{i}",
          visible_to_donor: true
        )
      end
    end
    it "return serialized donor_conditions", :show_in_doc do
      get :index
      expect(response.status).to eq(200)
      extra_ids = @extra_donor_conditions.map(&:id)
      returned = parsed_body['donor_conditions'].select { |c| extra_ids.include?(c['id']) }
      expect(returned.length).to eq(2)
    end

    it "returns 'visible_to_donor' in serialized response" do
      get :index
      expect(response.status).to eq(200)
      expect( parsed_body['donor_conditions'].map { |condition| condition['visible_to_donor']} ).to eq(DonorCondition.pluck(:visible_to_donor))
    end
  end
end
