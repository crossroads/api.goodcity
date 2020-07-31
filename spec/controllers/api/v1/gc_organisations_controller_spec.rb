require 'rails_helper'

RSpec.describe Api::V1::GcOrganisationsController, type: :controller do
  let(:supervisor) { create(:user, :with_token, :with_can_check_organisations_permission, role_name: 'Supervisor') }
  let(:parsed_body) { JSON.parse(response.body) }

  before { generate_and_set_token(supervisor) }

  describe "search gc organisations" do
    let(:organisations) { create_list(:organisation, 27)}

    it "returns first 25 results only" do
      organisations.map{|org| org.update_column(:name_en, org.name_en + " (HongKong)")}
      get :index, searchText: "(HongKong)"
      expect(parsed_body['gc_organisations'].length).to eq(25)
    end
  end

  describe 'GET gc organisations' do
    let(:organisations) { create_list(:organisation, 2) }

    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized organisations", :show_in_doc do
      get :index
      expect(parsed_body['gc_organisations'].length).to eq(Organisation.count)
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

    it "returns serialized organisations from an ID list" do
      create_list(:organisation, 2)
      more_organisations = create_list(:organisation, 3)
      ids =  more_organisations.map(&:id)

      get :index, ids: ids
      expect(parsed_body['gc_organisations'].length).to eq(ids.length)

      received_ids = parsed_body['gc_organisations'].map { |o| o["id"] }
      expect(received_ids).to match_array(ids)
    end

    it "returns serialized organisations names an ID list" do
      create_list(:organisation, 2)
      more_organisations = create_list(:organisation, 3)
      ids =  more_organisations.map(&:id)
      names =  more_organisations.map(&:name_en)

      get :index, ids: ids
      expect(parsed_body['gc_organisations'].length).to eq(ids.length)

      received_names = parsed_body['gc_organisations'].map { |o| o["name_en"] }
      expect(received_names).to match_array(names)
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

  describe "GET orders for GC organisation" do
    let(:organisation) { create :organisation }
    let(:organisation1) { create :organisation }
    let!(:organisation_orders) { create_list(:order, 2, organisation_id: organisation.id) }
    let!(:orders) { create_list(:order, 2) }
    let(:charity_user) { create :user, :charity, :with_can_manage_orders_permission }

    context "If logged in user is Supervisor" do
      before { generate_and_set_token(supervisor) }

      it "returns 200" do
        get :orders, id: organisation.id
        expect(response.status).to eq(200)
      end

      it "returns orders associated with organisation" do
        get :orders, id: organisation.id
        expect(parsed_body['designations'].size).to eq(organisation_orders.size)
        expect(parsed_body["designations"].map { |order| order["id"] }).to eq(organisation_orders.map(&:id))
      end

      it "does not returns orders of different organisation" do
        get :orders, id: organisation1.id
        expect(parsed_body['designations']).to eq([])
      end
    end

    context "denies access to Charity User" do
      before { generate_and_set_token(charity_user) }

      it "returns 403" do
        get :orders, id: organisation.id
        expect(response.status).to eq(403)
      end
    end

  end


end
