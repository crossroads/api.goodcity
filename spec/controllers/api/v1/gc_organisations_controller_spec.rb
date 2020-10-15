require 'rails_helper'

RSpec.describe Api::V1::GcOrganisationsController, type: :controller do
  let(:supervisor) { create(:user, :with_token, :with_can_check_organisations_permission, role_name: 'Supervisor') }
  let!(:country) { create(:country, name_en: DEFAULT_COUNTRY) }
  let(:parsed_body) { JSON.parse(response.body) }

  before { generate_and_set_token(supervisor) }

  describe "search gc organisations" do
    let(:organisations) { create_list(:organisation, 27)}

    it "returns first 25 results only" do
      organisations.map{|org| org.update_column(:name_en, org.name_en + " (HongKong)")}
      get :index, params: { searchText: "(HongKong)" }
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
      get :index, params: { searchText: name }
      expect(parsed_body['gc_organisations'].length ).to eq(1)
      expect(parsed_body['gc_organisations'][0]["id"]).to eq(organisation.id)
      expect(parsed_body['meta']['search']).to eql(name)
    end

    it "returns serialized organisations name_en with matching search text" do
      name = "Zuni"
      organisation = create :organisation, name_en: name
      get :names, params: { searchText: name }
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

      get :index, params: { ids: ids }
      expect(parsed_body['gc_organisations'].length).to eq(ids.length)

      received_ids = parsed_body['gc_organisations'].map { |o| o["id"] }
      expect(received_ids).to match_array(ids)
    end

    it "returns serialized organisations names an ID list" do
      create_list(:organisation, 2)
      more_organisations = create_list(:organisation, 3)
      ids =  more_organisations.map(&:id)
      names =  more_organisations.map(&:name_en)

      get :index, params: { ids: ids }
      expect(parsed_body['gc_organisations'].length).to eq(ids.length)

      received_names = parsed_body['gc_organisations'].map { |o| o["name_en"] }
      expect(received_names).to match_array(names)
    end
  end

  describe "GET GC Organisation" do
    let(:organisation) { create :organisation }
    let(:serialized_gc_organisation) { JSON.parse(Api::V1::OrganisationSerializer.new(organisation, root: "gc_organisations", include_orders_count: true).as_json.to_json) }

    before { get :show, params: { id: organisation.id } }
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
        get :orders, params: { id: organisation.id }
        expect(response.status).to eq(200)
      end

      it "returns orders associated with organisation" do
        get :orders, params: { id: organisation.id }
        expect(parsed_body['designations'].size).to eq(organisation_orders.size)
        expect(parsed_body["designations"].map { |order| order["id"] }).to eq(organisation_orders.map(&:id))
      end

      it "does not returns orders of different organisation" do
        get :orders, params: { id: organisation1.id }
        expect(parsed_body['designations']).to eq([])
      end
    end

    context "denies access to Charity User" do
      it "returns 403" do
        charity = create(:user, :charity)
        generate_and_set_token(charity)
        get :orders, params: { id: organisation.id }
        expect(response.status).to eq(403)
      end
    end
  end

  describe 'POST /create' do
    let(:organisation_type) { create(:organisation_type) }
    let(:params) { FactoryBot.attributes_for(:organisation, organisation_type_id: "#{organisation_type.id}") }
    let(:user) { create(:user, :with_order_administrator_role, :with_can_manage_organisations_permission) }

    before { generate_and_set_token(user) }

    it 'returns 200' do
      post :create, params: { organisation: params }
      expect(response).to have_http_status(:success)
    end

    it 'creates new organisation record' do
      expect {
        post :create, params: { organisation: params }
      }.to change { Organisation.count }.by(1)
    end

    context 'when name_en is already present' do
      it 'returns error' do
        create(:organisation, name_en: 'GOOD CITY')
        params[:name_en] = 'GooD CITY'
        expect {
          post :create, params: { organisation: params }
        }.not_to change { Organisation.count }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'if country is nil' do
      it 'sets to default country' do
        params[:country_id] = nil
        post :create, params: { organisation: params }
        country_id = Country.find_by(name_en: DEFAULT_COUNTRY).id
        expect(parsed_body['organisation']['country_id']).to eq(country_id)
      end
    end

    context 'if organisation type is nil' do
      it 'returns error' do
        params[:organisation_type_id] = nil
        post :create, params: { organisation: params }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not create new organisation' do
        params[:organisation_type_id] = nil
        expect { post :create, params: { organisation: params } }.not_to change { Organisation.count }
      end
    end

    context 'when invalid user' do
      let(:user) { create(:user) }

      it 'returns forbidden' do
        generate_and_set_token(user)
        post :create, params: { organisation: params }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'if registration is duplicate' do
      before do
        create(:organisation, registration: '123')
      end

      it 'response is 422' do
        params[:registration] = '123'
        post :create, params: { organisation: params }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(parsed_body['errors']).to include('Registration has already been taken')
      end

      it 'does not create organisation record' do
        params[:registration] = '123'
        expect{
          post :create, params: { organisation: params }
        }.not_to change { Organisation.count }
      end

      context 'when new registration has different case' do
        before do
          create(:organisation, registration: "A123")
        end

        it 'does not create organisation record' do
          params[:registration] = 'a123'
          post :create, params: { organisation: params }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(parsed_body['errors']).to include('Registration has already been taken')
        end

        it 'does not create organisation record' do
          params[:registration] = 'a123'
          expect {
            post :create, params: { organisation: params }
          }.not_to change { Organisation.count }
        end
      end
    end

    context 'if registration is empty' do
      it 'creates a new organisation for empty string' do
        create(:organisation, registration: '')

        params[:registration] = ''
        expect{
          post :create, params: { organisation: params }
        }.to change { Organisation.count }.by(1)
      end

      it 'creates a new organisation for nil' do
        create(:organisation, registration: nil)

        params[:registration] = nil
        expect {
          post :create, params: { organisation: params }
        }.to change { Organisation.count }.by(1)
      end
    end
  end

  describe 'PUT /update' do
    let!(:organisation) { create(:organisation) }
    let(:user) { create(:user, :with_order_administrator_role, :with_can_manage_organisations_permission) }
    before{ generate_and_set_token(user) }

    it 'updates the attribute' do
      put :update, params: { id: organisation.id, organisation: { name_en: 'Example' }}
      expect(organisation.reload.name_en).to eq('Example')
    end

    context 'when invalid user' do
      let(:user) { create(:user) }

      it 'returns forbidden' do
        generate_and_set_token(user)
        put :update, params: { id: organisation.id, name_en: 'Example'}
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'if name_en is duplicate' do
      it 'returns error' do
        create(:organisation, name_en: 'Good City')
        organisation = create(:organisation)
        put :update, params: { id: organisation.id, organisation: { name_en: 'good city   ' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not update the record' do
        create(:organisation, name_en: 'Good City')
        organisation = create(:organisation)
        name = organisation.name_en
        put :update, params: { id: organisation.id, organisation: { name_en: 'good city' } }
        expect(organisation.reload.name_en).to eq(name)
      end
    end

    context 'if organisation type is nil' do
      it 'returns error' do
        put :update, params: { id: organisation.id, organisation: { organisation_type_id: nil } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not change organisation_type_id' do
        put :update, params: { id: organisation.id, organisation: { organisation_type_id: nil } }
        expect(organisation.reload.organisation_type_id).to eq(organisation.organisation_type_id)
      end
    end

    context 'if registration is duplicate' do
      before do
        create(:organisation, registration: '123')
      end

      it 'response is 422' do
        put :update, params: { id: organisation.id, organisation: { registration: '123' } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(parsed_body['errors']).to include('Registration has already been taken')
      end

      it 'does not update organisation record' do
        put :update, params: { id: organisation.id, organisation: { registration: '123' } }
        expect(organisation.reload.registration).to eq(organisation.registration)
      end

      context 'when new registration has different case' do
        before do
          create(:organisation, registration: "A123")
        end

        it 'does not create organisation record' do
          put :update, params: { id: organisation.id, organisation: { registration: 'a123' } }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(parsed_body['errors']).to include('Registration has already been taken')
        end

        it 'does not create organisation record' do
          expect {
            put :update, params: { id: organisation.id, organisation: { registration: 'a123' } }
          }.not_to change { organisation.reload }
        end
      end
    end

    context 'if registration is empty' do
      it 'can update the organisation to empty string' do
        create(:organisation, registration: '')
        put :update, params: { id: organisation.id, organisation: { registration: 'abc' } }
        expect(organisation.reload.registration).to eq('abc')
      end

      it 'can update the organisation to nil' do
        create(:organisation, registration: nil)
        put :update, params: { id: organisation.id, organisation: { registration: nil } }
        expect(organisation.reload.registration).to be_empty
      end
    end
  end
end
