require 'rails_helper'

RSpec.describe Api::V1::TerritoriesController, type: :controller do

  let(:territory) { create(:territory_districts) }
  let(:serialized_territory) { Api::V1::TerritorySerializer.new(territory) }
  let(:serialized_territory_json) { JSON.parse( serialized_territory.to_json ) }

  let(:territories) { create_list(:territory, 2) }

  describe "GET territory" do
    it "returns 200" do
      get :show, id: territory.id
      expect(response.status).to eq(200)
    end

    it "return serialized territory", :show_in_doc do
      get :show, id: territory.id
      body = JSON.parse(response.body)
      expect( body ).to eq(serialized_territory_json)
    end
  end

  describe "GET territories" do
    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized territories", :show_in_doc do
      create(:territory_districts, districts_count: 2)
      create(:territory_districts, districts_count: 2)
      get :index
      body = JSON.parse(response.body)
      expect( body['territories'].length ).to eq(Territory.count)
    end
  end

end
