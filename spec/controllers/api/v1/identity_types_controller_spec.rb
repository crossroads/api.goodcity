require 'rails_helper'

RSpec.describe Api::V1::IdentityTypesController, type: :controller do

  let!(:id_type) { create :identity_type }
  let(:serialized_identity_type) { Api::V1::IdentityTypeSerializer.new(id_type).as_json }
  let(:parsed_body) { JSON.parse(response.body) }

  describe "GET one identity type" do
    it "returns 200" do
      get :show, id: id_type.id
      expect(response.status).to eq(200)
    end

    it "return serialized identity type", :show_in_doc do
      get :show, id: id_type.id
      expect(parsed_body).to eq( JSON.parse(serialized_identity_type.to_json) )
    end
  end

  describe "GET multiple identity types" do
    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized identity types", :show_in_doc do
      create(:identity_type)
      create(:identity_type)
      get :index
      expect(parsed_body['identity_types'].length).to eq(IdentityType.count)
    end
  end

end
