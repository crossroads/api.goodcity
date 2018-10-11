require 'rails_helper'

RSpec.describe Api::V1::OrdersController, type: :controller do
  let(:charity_user) { create :user, :charity, :with_can_manage_orders_permission}
  let!(:order) { create :order, :with_state_submitted, created_by: charity_user }
  let(:draft_order) { create :order, :with_orders_packages, :with_state_draft, status: nil }
  let(:draft_order_with_status) { create :order, :with_orders_packages, :with_state_draft }
  let(:user) { create(:user_with_token, :with_multiple_roles_and_permissions,
    roles_and_permissions: { 'Supervisor' => ['can_manage_orders']} )}
  let!(:order_created_by_supervisor) { create :order, :with_state_submitted, created_by: user }
  let(:parsed_body) { JSON.parse(response.body) }
  let(:order_params) { FactoryBot.attributes_for(:order, :with_stockit_id) }

  describe "GET orders" do
    context 'If logged in user is Supervisor in Browse app ' do

      before { generate_and_set_token(user) }

      it "returns 200", :show_in_doc do
        get :index
        expect(response.status).to eq(200)
      end

      it 'returns orders created by logged in user when user is supervisor and if its browse app' do
        set_browse_app_header
        get :index
        expect(parsed_body['orders'].count).to eq(1)
        expect(parsed_body["orders"][0]['id']).to eq(order_created_by_supervisor.id)
      end
    end

    context 'If logged in user is Charity user' do

      before { generate_and_set_token(charity_user) }

      it "returns 200", :show_in_doc do
        get :index
        expect(response.status).to eq(200)
      end

      it 'returns orders created by logged in user' do
        request.headers["X-GOODCITY-APP-NAME"] = "browse.goodcity"
        get :index
        expect(parsed_body['orders'].count).to eq(1)
        expect(parsed_body["orders"][0]['id']).to eq(order.id)
      end
    end

    context 'Admin app' do
      before { generate_and_set_token(user) }

      it 'returns all orders as designations for admin app if search text is not present' do
        request.headers["X-GOODCITY-APP-NAME"] = "admin.goodcity"
        get :index
        expect(response.status).to eq(200)
        expect(parsed_body['designations'].count).to eq(2)
      end
    end

    context 'Stock App' do
      before {
        generate_and_set_token(user)
        request.headers["X-GOODCITY-APP-NAME"] = "stock.goodcity"
      }

      it 'returns the number of items specified for the page' do
        5.times { FactoryBot.create :order, :with_state_submitted } # There are now 7 no-draft orders in total
        get :index, page: 1, per_page: 5
        expect(parsed_body['designations'].count).to eq(5)
      end

      it 'returns the remaining items in the last page' do
        5.times { FactoryBot.create :order, :with_state_submitted } # There are now 7 non-draft orders in total
        get :index, page: 2, per_page: 5
        expect(parsed_body['designations'].count).to eq(2)
      end

      it 'returns searched non-draft order as designation if search text is present' do
        get :index, searchText: order.code
        expect(response.status).to eq(200)
        expect(parsed_body['designations'].count).to eq(1)
        expect(parsed_body["designations"][0]['id']).to eq(order.id)
        expect(parsed_body['meta']['total_pages']).to eql(1)
        expect(parsed_body['meta']['search']).to eql(order.code)
      end

      it 'returns empty response if search text is draft order' do
        get :index, searchText: draft_order.code
        expect(response.status).to eq(200)
        expect(parsed_body['designations'].count).to eq(0)
        expect(parsed_body['meta']['total_pages']).to eql(0)
      end

      it 'can search orders using their description (case insensitive)' do
        order = FactoryBot.create :order, :with_state_submitted, description: 'IPhone 100s'
        get :index, searchText: 'iphone'
        expect(response.status).to eq(200)
        expect(parsed_body['designations'].count).to eq(1)
        expect(parsed_body["designations"][0]['description']).to eq('IPhone 100s')
        expect(parsed_body['meta']['total_pages']).to eql(1)
        expect(parsed_body['meta']['search']).to eql('iphone')
      end

      it 'can search orders by the organization that submitted them' do
        organisation = FactoryBot.create :organisation, name_en: "Crossroads Foundation LTD"
        FactoryBot.create :order, :with_state_submitted, organisation: organisation
        get :index, searchText: 'crossroads'
        expect(response.status).to eq(200)
        expect(parsed_body['designations'].count).to eq(1)
        expect(parsed_body["designations"][0]['gc_organisation_id']).to eq(organisation.id)
        expect(parsed_body['meta']['total_pages']).to eql(1)
        expect(parsed_body['meta']['search']).to eql('crossroads')
      end

      it "can search orders from a user's first or last name" do
        submitter = FactoryBot.create :user, first_name: 'Jane', last_name: 'Doe'
        FactoryBot.create :order, :with_state_submitted, submitted_by: submitter
        get :index, searchText: 'jan'
        expect(response.status).to eq(200)
        expect(parsed_body['designations'].count).to eq(1)
        expect(parsed_body["designations"][0]['submitted_by_id']).to eq(submitter.id)
        expect(parsed_body['meta']['total_pages']).to eql(1)
        expect(parsed_body['meta']['search']).to eql('jan')
      end

      it "can search orders from a user's full name" do
        submitter = FactoryBot.create :user, first_name: 'John', last_name: 'Smith'
        FactoryBot.create :order, :with_state_submitted, submitted_by: submitter
        get :index, searchText: 'john smith'
        expect(response.status).to eq(200)
        expect(parsed_body['designations'].count).to eq(1)
        expect(parsed_body["designations"][0]['submitted_by_id']).to eq(submitter.id)
        expect(parsed_body['meta']['total_pages']).to eql(1)
        expect(parsed_body['meta']['search']).to eql('john smith')
      end

      it 'returns goodcity order if search text is non draft goodcity order with toDesignateItem params' do
        get :index, searchText: order.code, toDesignateItem: true
        expect(response.status).to eq(200)
        expect(parsed_body['designations'].count).to eq(1)
        expect(parsed_body['meta']['total_pages']).to eql(1)
      end

      it 'do not returns goodcity order if search text is draft goodcity order with toDesignateItem params' do
        get :index, searchText: draft_order.code, toDesignateItem: true
        expect(response.status).to eq(200)
        expect(parsed_body['designations'].count).to eq(0)
        expect(parsed_body['meta']['total_pages']).to eql(0)
      end

      it 'returns goodicty order if search text is non-draft goodcity order with toDesignateItem params even if status is active_status list' do
        get :index, searchText: draft_order_with_status.code, toDesignateItem: true
        expect(response.status).to eq(200)
        expect(parsed_body['designations'].count).to eq(1)
        expect(parsed_body['meta']['total_pages']).to eql(1)
      end

      it "should be able to fetch designations without their associations" do
        get :index, shallow: 'true'
        expect(response.status).to eq(200)
        expect(parsed_body.keys.length).to eq(2)
        expect(parsed_body).to have_key('designations')
        expect(parsed_body).to have_key('meta')
      end

    end
  end

  describe "PUT orders/1" do
    before { generate_and_set_token(charity_user) }
    context 'should merge offline cart orders_packages on login with order' do
      it "if order is in draft state" do
        package = create :package, quantity: 1, received_quantity: 1
        package_ids = draft_order.orders_packages.pluck(:package_id)
        put :update, id: draft_order.id, order: { cart_package_ids: package_ids.push(package.id) }
        expect(response.status).to eq(200)
        expect(draft_order.orders_packages.count).to eq(4)
      end
    end
  end

  describe "POST orders" do
    context 'If logged in user is Supervisor in Browse app ' do
      before { generate_and_set_token(user) }

      it 'should create an order via POST method' do
        set_browse_app_header
        post :create, order: order_params
        expect(response.status).to eq(201)
        expect(parsed_body['order']['people_helped']).to eq(order_params[:people_helped])
      end

      it 'should create an order with nested beneficiary' do
        set_browse_app_header
        beneficiary_count = Beneficiary.count
        order_params['beneficiary_attributes'] = FactoryBot.build(:beneficiary).attributes.except('id', 'updated_at', 'created_at', 'created_by_id')
        post :create, order: order_params
        expect(response.status).to eq(201)
        expect(Beneficiary.count).to eq(beneficiary_count + 1)
        beneficiary = Beneficiary.find_by(id: parsed_body['order']['beneficiary_id'])
        expect(beneficiary.created_by_id).to eq(user.id)
      end

    end
  end

end
