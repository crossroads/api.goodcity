require 'rails_helper'

RSpec.describe Api::V1::GcOrganisationsController, type: :controller do
  let(:supervisor) { create(:user_with_token, :with_can_check_organisations_permission, role_name: 'Supervisor') }
  before { generate_and_set_token(supervisor) }

  describe 'GET gc organisations' do
    let(:organisations) { create_list(:organisation, 2) }

    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized organisations", :show_in_doc do
      get :index
      body = JSON.parse(response.body)
      expect( body['gc_organisations'].length ).to eq(Organisation.count)
    end

    it "returns serialized organisations with matching search text" do
      organisation = create :organisation, name_en: 'Zuni'
      get :index, search_text: organisation.name_en
      body = JSON.parse(response.body)
      expect(body['gc_organisations'].length ).to eq(1)
      expect(body['gc_organisations'][0]["id"]).to eq(organisation.id)
    end
  end

  describe "GET GC Organisation" do
    let(:organisation) { create :organisation }
    let(:serialized_gc_orgnisation) { Api::V1::OrganisationSerializer.new(organisation, root: "gc_organisations") }

    it "returns 200" do
      get :show, id: organisation.id
      expect(response.status).to eq(200)
    end

    it "return serialized address", :show_in_doc do
      get :show, id: organisation.id
      expect(response.body).to eq(serialized_gc_orgnisation.to_json)
    end
  end
end
