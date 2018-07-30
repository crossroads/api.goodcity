require 'rails_helper'

RSpec.describe Api::V1::DistrictsController, type: :controller do

  let(:district) { create(:district) }
  let(:serialized_district) { Api::V1::DistrictSerializer.new(district).as_json }
  let(:serialized_district_json) { JSON.parse( serialized_district.to_json ) }
  let(:parsed_body) { JSON.parse(response.body) }
  let(:districts) { create_list(:district, 2) }

  describe "GET district" do
    it "returns 200" do
      get :show, id: district.id
      expect(response.status).to eq(200)
    end

    it "return serialized district", :show_in_doc do
      get :show, id: district.id
      expect(parsed_body).to eq(serialized_district_json)
    end
  end

  describe "GET districts" do
    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized districts", :show_in_doc do
      create(:district)
      create(:district)
      get :index
      expect(parsed_body['districts'].length).to eq(District.count)
    end
  end

end
