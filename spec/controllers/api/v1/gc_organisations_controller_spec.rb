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
      it "returns 403" do
        charity = create(:user, :charity)
        generate_and_set_token(charity)
        get :orders, id: organisation.id
        expect(response.status).to eq(403)
      end
    end
  end

  describe 'POST /create' do
    let(:organisation_type) { create(:organisation_type) }
    let(:params) { FactoryBot.attributes_for(:organisation, organisation_type_id: "#{organisation_type.id}") }
    let(:user) { create(:user, :with_order_administrator_role, :with_can_manage_organisation_permission) }

    before { generate_and_set_token(user) }

    it 'returns 200' do
      post :create, organisation: params
      expect(response).to have_http_status(:success)
    end

    it 'creates new organisation record' do
      expect {
        post :create, organisation: params
      }.to change { Organisation.count }.by(1)
    end

    context 'when name_en is already present' do
      it 'returns error' do
        create(:organisation, name_en: 'GOOD CITY')
        params[:name_en] = 'GOOD CITY'
        expect {
          post :create, organisation: params
        }.not_to change { Organisation.count }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'if country is nil' do
      it 'sets to default country' do
        params[:country_id] = nil
        post :create, organisation: params
        country_id = Country.find_by(name_en: DEFAULT_COUNTRY).id
        expect(parsed_body['organisation']['country_id']).to eq(country_id)
      end
    end

    context 'if organisation type is nil' do
      it 'returns error' do
        params[:organisation_type_id] = nil
        post :create, organisation: params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not create new organisation' do
        params[:organisation_type_id] = nil
        expect { post :create, organisation: params }.not_to change { Organisation.count }
      end
    end

    context 'when invalid user' do
      let(:user) { create(:user) }

      it 'returns forbidden' do
        generate_and_set_token(user)
        post :create, organisation: params
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PUT /update' do
    let!(:organisation) { create(:organisation) }
    let(:user) { create(:user, :with_order_administrator_role, :with_can_manage_organisation_permission) }
    before{ generate_and_set_token(user) }

    it 'updates the attribute' do
      put :update, id: organisation.id, organisation: { name_en: 'Example' }
      expect(organisation.reload.name_en).to eq('EXAMPLE')
    end

    context 'when invalid user' do
      let(:user) { create(:user) }

      it 'returns forbidden' do
        generate_and_set_token(user)
        put :update, id: organisation.id, name_en: 'Example'
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'if name_en is duplicate' do
      it 'returns error' do
        create(:organisation, name_en: 'Good City')
        organisation = create(:organisation)
        put :update, id: organisation.id, organisation: { name_en: 'good city' }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not update the record' do
        create(:organisation, name_en: 'Good City')
        organisation = create(:organisation)
        put :update, id: organisation.id, organisation: { name_en: 'good city' }
        expect(organisation.reload.name_en).to eq(organisation.name_en)
      end
    end

    context 'if organisation type is nil' do
      it 'returns error' do
        put :create, organisation: { organisation_type_id: nil }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not change organisation_type_id' do
        post :create, organisation: { organisation_type_id: nil }
        expect(organisation.reload.organisation_type_id).to eq(organisation.organisation_type_id)
      end
    end
  end
end
