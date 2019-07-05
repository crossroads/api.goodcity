require 'rails_helper'

RSpec.describe Api::V1::TerritoriesController, type: :controller do

  let(:territory) { create(:territory_districts) }
  let(:serialized_territory) { Api::V1::TerritorySerializer.new(territory) }
  let(:parsed_body) { JSON.parse(response.body) }

  describe "GET territory" do
    before { get :show, id: territory.id}
    it "returns 200" do
      expect(response.status).to eq(200)
    end
    it "return serialized territory", :show_in_doc do  
      expect(parsed_body['territory']['id']).to eq(serialized_territory.id)
      expect(parsed_body['territory']['name']).to eq(serialized_territory.name)
      expect(parsed_body['territory']['district_ids']).to match_array(serialized_territory.districts.map(&:id))
    end
  end

  describe "GET territories" do
    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized territories", :show_in_doc do
      2.times { create(:territory) }
      get :index
      expect( parsed_body['territories'].length ).to eq(Territory.count)
    end

    it 'returns territories with ids present in params' do
      2.times { create :territory }
      get :index, ids: [territory.id]
      expect(response.status).to eq(200)
      expect(parsed_body['territories'].length).to eq(1)
      expect(assigns(:territories).to_a).to eq([territory])
    end
  end

end
