require 'rails_helper'

RSpec.describe Api::V1::GcOrganisationsController, type: :controller do
  let(:supervisor) { create(:user_with_token, :with_can_check_organisations_permission, role_name: 'Supervisor') }
  let(:parsed_body) { JSON.parse(response.body) }

  before { generate_and_set_token(supervisor) }

  describe 'GET gc organisations' do
    let(:organisations) { create_list(:organisation, 2) }

    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized organisations", :show_in_doc do
      get :index
      expect( parsed_body['gc_organisations'].length ).to eq(Organisation.count)
    end

    it "returns serialized organisations with matching search text" do
      name = "Zuni"
      organisation = create :organisation, name_en: name
      get :index, searchText: name
      expect(parsed_body['gc_organisations'].length ).to eq(1)
      expect(parsed_body['gc_organisations'][0]["id"]).to eq(organisation.id)
      expect(parsed_body['meta']['search']).to eql(name)
    end

    it "returns serialized organisations name_en with matching search text" do
      name = "Zuni"
      organisation = create :organisation, name_en: name
      get :names, searchText: name
      expect(parsed_body['gc_organisations'].length ).to eq(1)
      expect(parsed_body['gc_organisations'][0]["id"]).to eq(organisation.id)
      expect(parsed_body['meta']['search']).to eql(name)
      expect(parsed_body['gc_organisations'].first['name_en']).to eql(organisation.name_en)
      expect(parsed_body['gc_organisations'].first['name_zh_tw']).to eql(organisation.name_zh_tw)
    end
  end

  describe "GET GC Organisation" do
    let(:organisation) { create :organisation }
    let(:serialized_gc_organisation) { JSON.parse(Api::V1::OrganisationSerializer.new(organisation, root: "gc_organisations").as_json.to_json) }

    before { get :show, id: organisation.id }
    it "returns 200" do
      expect(response.status).to eq(200)
    end

    it "return serialized address", :show_in_doc do
      expect(parsed_body).to eq(serialized_gc_organisation)
    end
  end
end
