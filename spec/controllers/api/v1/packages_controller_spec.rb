require "rails_helper"

RSpec.describe Api::V1::PackagesController, type: :controller do
  let(:supervisor) { create(:user, :supervisor, :with_can_manage_packages_permission )}
  let(:user) { create(:user_with_token, :with_multiple_roles_and_permissions,
    roles_and_permissions: { 'Reviewer' => ['can_manage_packages', 'can_manage_orders']} )}
  let!(:stockit_user) { create(:user, :stockit_user, :api_user)}
  let(:donor) { create(:user_with_token) }
  let(:offer) { create :offer, created_by: donor }
  let(:item)  { create :item, offer: offer }
  let(:package_type)  { create :package_type }
  let(:package) { create :package, item: item }
  let(:package_with_stockit_id) { create :package, :stockit_package, item: item }
  let(:orders_package) { create :orders_package, package: package }
  let(:serialized_package) { Api::V1::PackageSerializer.new(package).as_json }
  let(:serialized_package_json) { JSON.parse( serialized_package.to_json ) }
  let(:parsed_body) { JSON.parse(response.body) }

  let(:package_params) do
    FactoryBot.attributes_for(:package, item_id: "#{item.id}", package_type_id: "#{package_type.id}")
  end

  subject { JSON.parse(response.body) }

  def test_package_changes(package, response_status, designation_name, location)
    expect(package.reload.designation_name).to eq(designation_name)
    expect(package.locations.first).to eq(location)
    expect(package.donor_condition).to eq(donor_condition)
    expect(package.grade).to eq("C")
    expect(response_status).to eq(201)
  end

  def test_orders_packages(package, stockit_request, count)
    expect(package.orders_packages.count).to eq count
    expect(stockit_request).to eq(true)
  end

  def test_packages_location_changes(package)
    expect(package.packages_locations.count).to eq 1
    expect(package.locations.first.building).to eq 'Dispatched'
  end

  describe "Dispatching item" do
    before { generate_and_set_token(user) }
    let(:order) { create :order, state: Order::ORDER_UNPROCESSED_STATES.sample}
    let(:orders_package) { create :orders_package, package: package, order: order }

    it "throws error if order is not processed" do
      put :dispatch_stockit_item, id: package.id, package: {
        order_package_id: orders_package.id }
      expect(response.status).to eq(403)
      expect(subject['errors']).to eq('You need to complete processing Order first before dispatching.')
    end
  end

  describe "GET packages for Item" do

    context 'as a user' do
      before { generate_and_set_token(user) }
      it "returns 200" do
        get :index
        expect(response.status).to eq(200)
      end
      it "return serialized packages", :show_in_doc do
        3.times{ create :package }
        get :index
        expect( subject["packages"].size ).to eq(3)
      end

      it "returns searched packages" do
        set_browse_app_header
        3.times{ create :package, notes: "Baby towels", allow_web_publish: false }
        3.times{ create :browseable_package, notes: "Baby car seats" }
        expect(Package.count).to eq(6)
        get :index, "searchText": "car"
        expect(response.status).to eq(200)
        expect( subject["packages"].size ).to eq(3)
      end

      it "returns searched browseable_packages only" do
        set_browse_app_header
        3.times{ create :package, notes: "Baby towels", allow_web_publish: false }
        3.times{ create :browseable_package, notes: "Baby car seats" }
        pkg = create :browseable_package, notes: "towels"
        expect(Package.count).to eq(7)
        get :index, "searchText": "towel"
        expect(response.status).to eq(200)
        expect( subject["packages"].size ).to eq(1)
      end
    end

    context "as an anonymous user" do
      before { request.headers['Authorization'] = nil }

      it "should allow fetching a published package" do
        published_package = create :package, :published
        get :show, id: published_package.id
        expect(response.status).to eq(200)
      end

      it "should prevent fetching an unpublished package" do
        published_package = create :package, :unpublished
        get :show, id: published_package.id
        expect(response.status).to eq(403)
      end

      it "returns searched packages" do
        set_browse_app_header
        3.times{ create :package, notes: "Baby towels", allow_web_publish: false }
        3.times{ create :browseable_package, notes: "Baby Toilets" }
        expect(Package.count).to eq(6)
        get :index, "searchText": "Baby"
        expect(response.status).to eq(200)
        expect( subject["packages"].size ).to eq(3)
      end

      it "returns searched browseable_packages only" do
        set_browse_app_header
        3.times{ create :package, notes: "Baby towels", allow_web_publish: false }
        3.times{ create :browseable_package, notes: "Baby car seats" }
        pkg = create :browseable_package, notes: "towels"
        expect(Package.count).to eq(7)
        get :index, "searchText": "towel"
        expect(response.status).to eq(200)
        expect( subject["packages"].size ).to eq(1)
      end
    end

    context "as a disabled user" do
      before do
        supervisor.disabled = true
        supervisor.save
        generate_and_set_token(supervisor)
      end

      it "should allow fetching a published package" do
        published_package = create :package, :published
        get :show, id: published_package.id
        expect(response.status).to eq(200)
      end

      it "should prevent fetching an unpublished package" do
        published_package = create :package, :unpublished
        get :show, id: published_package.id
        expect(response.status).to eq(403)
      end
    end

    context "as a supervisor" do
      before { generate_and_set_token(supervisor) }

      it "should allow fetching a published package" do
        published_package = create :package, :published
        get :show, id: published_package.id
        expect(response.status).to eq(200)
      end

      it "should allow fetching an unpublished package" do
        published_package = create :package, :unpublished
        get :show, id: published_package.id
        expect(response.status).to eq(200)
      end
    end
  end

 describe "Moving the package (PUT /:id/move) " do
    before { generate_and_set_token(user) }

    let!(:location1) { create :location }
    let!(:location2) { create :location }
    let!(:package) { create :package, received_quantity: 1 }
    let!(:packages_location) { create(:packages_location, package: package, location: location1, quantity: 5) }

    it 'moves the entire quantity to the desired location' do
      expect(Stockit::ItemSync).to receive(:move)
      expect(package.packages_locations.length).to eq(1)
      expect(package.packages_locations.first.location).to eq(location1)
      expect(package.packages_locations.first.quantity).to eq(5)

      put :move, format: :json, id: package.id, quantity: 5, from: location1.id, to: location2.id

      package.reload
      expect(package.packages_locations.length).to eq(1)
      expect(package.packages_locations.first.location).to eq(location2)
      expect(package.packages_locations.first.quantity).to eq(5)
    end

    it 'moves part of the quantity to the desired location' do
      expect(package.packages_locations.length).to eq(1)
      expect(package.packages_locations.first.location).to eq(location1)
      expect(package.packages_locations.first.quantity).to eq(5)

      put :move, format: :json, id: package.id, quantity: 3, from: location1.id, to: location2.id

      package.reload
      expect(package.packages_locations.length).to eq(2)
      expect(package.packages_locations.first.location).to eq(location1)
      expect(package.packages_locations.first.quantity).to eq(2)
      expect(package.packages_locations.last.location).to eq(location2)
      expect(package.packages_locations.last.quantity).to eq(3)
    end

    it 'updates existing packages_location with the moved quantity' do
      create(:packages_location, package: package, quantity: 1, location: location2)

      expect(package.packages_locations.length).to eq(2)
      expect(package.packages_locations.first.location).to eq(location1)
      expect(package.packages_locations.first.quantity).to eq(5)
      expect(package.packages_locations.last.location).to eq(location2)
      expect(package.packages_locations.last.quantity).to eq(1)

      put :move, format: :json, id: package.id, quantity: 3, from: location1.id, to: location2.id

      package.reload
      expect(package.packages_locations.length).to eq(2)
      expect(package.packages_locations.first.location).to eq(location1)
      expect(package.packages_locations.first.quantity).to eq(2)
      expect(package.packages_locations.last.location).to eq(location2)
      expect(package.packages_locations.last.quantity).to eq(4)
    end

    context 'with bad parameters' do
      let(:error_msg) do
        return parsed_body['error'] if parsed_body['error'].present?
        parsed_body['errors'][0]['message']
      end

      it 'fails if the from location is missing' do
        put :move, format: :json, id: package.id, quantity: 3, to: location2.id
        expect(response.status).to eq(404)
        expect(error_msg).to match(/^Couldn't find Location/)
      end

      it 'fails if the to location is missing' do
        put :move, format: :json, id: package.id, quantity: 3, from: location2.id
        expect(response.status).to eq(404)
        expect(error_msg).to match(/^Couldn't find Location/)
      end

      it 'fails if the the package_id is wrong' do
        put :move, format: :json, id: '9999', from: location2.id
        expect(response.status).to eq(404)
        expect(error_msg).to match(/^Couldn't find Package with 'id'=9999/)
      end

      it 'fails if the quantity is missing' do
        put :move, format: :json, id: package.id, from: location2.id
        expect(response.status).to eq(422)
        expect(error_msg).to match(/^Invalid move quantity/)
      end
    end
  end

  describe "POST package/1" do
   before { generate_and_set_token(user) }

    context "create package from gc" do
      it "reviewer can create", :show_in_doc do
        post :create, format: :json, package: package_params
        expect(response.status).to eq(201)
        expect(GoodcitySync.request_from_stockit).to eq(false)
      end
    end

    context "create package from gc with sub detail" do
      let!(:location) { create :location }
      let!(:code) { create :package_type, :with_stockit_id }
      let(:computer_params) { FactoryBot.attributes_for(:computer) }
      let(:stockit_item_params) {
        {
          quantity: 1,
          inventory_number: '123456',
          location_id: location.stockit_id,
          grade: "C",
          stockit_id: 1,
          code_id: code.stockit_id
        }
      }
      let(:package_params_with_details){
        stockit_item_params.merge({
          quantity: 1,
          received_quantity: package.received_quantity,
          package_type_id:package.package_type_id,
          state: package.state,
          stockit_id: package.stockit_id,
          donor_condition_id: package.donor_condition_id,
          detail_attributes: computer_params,
          detail_type: "computer"
        })
      }

      let(:package_params_with_details_incorrect_params){
        stockit_item_params.merge({
          quantity: 0,
          received_quantity: 0,
          package_type_id:package.package_type_id,
          state: package.state,
          stockit_id: package.stockit_id,
          donor_condition_id: package.donor_condition_id,
          detail_attributes: computer_params,
          detail_type: "computer"
        })
      }

      describe "creating package with detail" do
        it "creates package with detail" do
          allow(Stockit::ItemDetailSync).to receive(:create).and_return({"status"=>201, "computer_id"=> 12})
          post :create, format: :json, package: package_params_with_details
          expect(response.status).to eq(201)
          package = Package.last
          expect(parsed_body["package"]["id"]).to eq(package.id)
          expect(parsed_body["package"]["detail_type"]).to eq(package.detail_type)
          expect(parsed_body["package"]["detail_id"]).to eq(package.detail_id)
        end

        it "does not create package with detail if anything fails in package" do
          allow(Stockit::ItemDetailSync).to receive(:create).and_return({"status"=>201, "computer_id"=> 12})
          post :create, format: :json, package: package_params_with_details_incorrect_params
          expect(parsed_body["errors"]).to_not be_nil
        end
      end
    end

    describe "Received from Stockit" do
      let!(:location) { create :location }
      let!(:order) { create :order, :with_stockit_id }
      let(:order_1) { create :order, :with_stockit_id }
      let!(:code) { create :package_type, :with_stockit_id }
      let(:donor_condition) { create :donor_condition }
      let!(:dispatched_location) { create :location, :dispatched }
      # let!(:location_1) { create :location }
      let(:stockit_item_params) {
        {
          quantity: 1,
          inventory_number: '123456',
          location_id: location.stockit_id,
          donor_condition_id: donor_condition.id,
          grade: "C",
          stockit_id: 1,
          code_id: code.stockit_id
        }
      }

      before(:each) do
        allow(Date).to receive(:today).and_return Date.new(2001,2,3)
      end

      context 'Designate & undesignate from stockit' do

        before(:all) do
          WebMock.disable!
        end

        after(:all) do
          WebMock.enable!
        end

        let(:order1) { create :order }


        let(:stockit_item_params_with_designation){
          stockit_item_params.merge({
            stockit_designated_on: Date.today,
            designation_name: order.code,
            order_id: order.stockit_id,
            location_id: location.stockit_id
          })
        }

        let(:stockit_item_params_without_designation){
          stockit_item_params.merge({
            designation_name: '',
            order_id: nil,
            stockit_id: package_with_stockit_id.stockit_id,
            location_id: location.stockit_id
          })
        }

        it "create new package with designation for newly created item from stockit with designation", :show_in_doc do
          expect{
            post :create, format: :json, package: stockit_item_params_with_designation
          }.to change(Package, :count).by(1)
          package = Package.where(inventory_number: stockit_item_params_with_designation[:inventory_number]).first
          test_package_changes(package, response.status, order.code, location)
          stockit_request = GoodcitySync.request_from_stockit
          test_orders_packages(package, stockit_request, 1)
          expect(package.orders_packages.first.state).to eq 'designated'
          expect(package.orders_packages.first.quantity).to eq 1
          expect(package.quantity).to eq(0)
          expect(package.reload.stockit_designated_by_id).to eq(stockit_user.id)
          expect(package.location_id).to eq location.id
        end

        it 'do not creates any orders_package if designation name was nil and not changed' do
          expect{
            post :create, format: :json, package: stockit_item_params_without_designation
          }.to change(OrdersPackage, :count).by(0)
          test_package_changes(package_with_stockit_id, response.status, '', location)
          stockit_request = GoodcitySync.request_from_stockit
          test_orders_packages(package, stockit_request, 0)
        end

        it 'creates orders_package for already existing item which is now designated from stockit' do
          package = create :package, :stockit_package, item: item
          stockit_item_params_with_designation[:stockit_id] = package.stockit_id
          expect{
            post :create, format: :json, package: stockit_item_params_with_designation
          }.to change(OrdersPackage, :count).by(1)
          test_package_changes(package, response.status, order.code, location)
          stockit_request = GoodcitySync.request_from_stockit
          expect(package.reload.stockit_designated_by_id).to eq(stockit_user.id)
          test_orders_packages(package, stockit_request, 1)
        end

        it 'updates designation if item has designation in stockit and then designated to some other designation' do
          package = create :package, :stockit_package, item: item, quantity: 0, received_quantity: 1
          order1 = create :order
          orders_package = create :orders_package, :with_state_designated, order: order1,
            package: package, quantity: 1
          stockit_item_params_with_designation[:stockit_id] = package.stockit_id
          expect{
            post :create, format: :json, package: stockit_item_params_with_designation
          }.to change(OrdersPackage, :count).by(0)
          test_package_changes(package, response.status, order.code, location)
          stockit_request = GoodcitySync.request_from_stockit
          test_orders_packages(package, stockit_request, 1)
          expect(package.reload.stockit_designated_by_id).to eq(stockit_user.id)
          expect(package.orders_packages.first.order).to eq order
          expect(package.orders_packages.first.state).to eq 'designated'
        end

        it 'removes designation if item was previously designated and now its undesignated from stockit' do
          package = create :package, :stockit_package, designation_name: 'abc', order: order,
            quantity: 0, received_quantity: 1
          orders_package = create :orders_package, :with_state_designated, order: order,
            package: package, quantity: 1
          packages_location = create :packages_location, package: package, location: location,
            quantity: package.received_quantity
          stockit_item_params_without_designation[:stockit_id] = package.reload.stockit_id
          expect{
            post :create, format: :json, package: stockit_item_params_without_designation
          }.to change(OrdersPackage, :count).by(-1)
          test_package_changes(package, response.status, '', location)
          expect(package.reload.stockit_designated_by_id).to be_nil
          expect(package.reload.stockit_sent_by_id).to be_nil
          stockit_request = GoodcitySync.request_from_stockit
          test_orders_packages(package, stockit_request, 0)
        end

        it 'updates existing orders_package order_id if designated to some other order' do
          package = create :package, :stockit_package, designation_name: order1.code, quantity: 0, received_quantity: 1
          orders_package = create :orders_package, :with_state_designated, order: order1, package: package, quantity: 1
          packages_location = create :packages_location, package: package, location: location,
            quantity: package.received_quantity
          stockit_item_params_with_designation[:stockit_id] = package.reload.stockit_id
          expect{
            post :create, format: :json, package: stockit_item_params_with_designation
          }.to change(OrdersPackage, :count).by(0)
          test_package_changes(package, response.status, order.code, location)
          stockit_request = GoodcitySync.request_from_stockit
          test_orders_packages(package, stockit_request, 1)
          expect(package.orders_packages.first.state).to eq('designated')
        end
      end

      context 'Update quantity from Stockit' do
        let(:order) { create :order, :with_stockit_id }
        let(:package) { create :package, :stockit_package, quantity: 0, received_quantity: 1 }
        let!(:orders_package) { create :orders_package, :with_state_designated, order: order, package: package, quantity: 1 }

        let(:package_params){
          stockit_item_params.merge({
            quantity: 1,
            received_quantity: package.received_quantity,
            package_type_id:package.package_type_id,
            state: package.state,
            stockit_id: package.stockit_id,
            donor_condition_id: package.donor_condition_id,
            designation_name: order.code,
            order_id: order.stockit_id
          })
        }

        it 'update quantity of item with edit' do
          post :create, format: :json, package: package_params
          expect(response.status).to eq(201)
          expect(package.reload.quantity).to eq(0)
        end
      end

      context 'Update quantity of item with Designate and Dispatch operation from Stockit' do

        before(:all) do
          WebMock.disable!
        end

        after(:all) do
          WebMock.enable!
        end

        let(:order1) { create :order }
        let(:order) { create :order, :with_stockit_id }
        let(:package) {create :package, :stockit_package, designation_name: order1.code, received_quantity: 10,
          quantity: 0 }

        let(:stockit_params_with_sent_on_and_designation){
          stockit_item_params.merge({
            stockit_sent_on: Date.today,
            stockit_designated_on: Date.today,
            designation_name: order.code,
            order_id: order.stockit_id
          })
        }

        it 'updates quantity of package, orders_package and packages_location record if item(designated) quantity is changed from stockit' do
          orders_package = create :orders_package, :with_state_designated, order: order,
            package: package, quantity: 10
          packages_location = create :packages_location, package: package, location: location,
          quantity: package.received_quantity
          stockit_params_with_sent_on_and_designation[:quantity] = 8
          stockit_params_with_sent_on_and_designation[:stockit_id] = package.stockit_id
          expect{
            post :create, format: :json, package: stockit_params_with_sent_on_and_designation
          }.to change(OrdersPackage, :count).by(0)
          stockit_request = GoodcitySync.request_from_stockit
          test_orders_packages(package, stockit_request, 1)
          expect(package.quantity).to eq(0)
          expect(package.reload.received_quantity).to eq(8)
          expect(orders_package.reload.quantity).to eq(8)
          expect(package.packages_locations.first.quantity).to eq(8)
        end
      end

      context 'Dispatch & Undispatch from stockit' do
        before(:all) do
          WebMock.disable!
        end

        after(:all) do
          WebMock.enable!
        end

        let(:stockit_params_with_sent_on_and_designation){
          stockit_item_params.merge({
            stockit_designated_on: Date.today,
            stockit_sent_on: Date.today,
            designation_name: order.code,
            order_id: order.stockit_id
          })
        }

        let(:stockit_params_without_sent_on){
          stockit_item_params.merge({
            stockit_sent_on: '',
            designation_name: order.code,
            order_id: order.stockit_id,
            location_id: ""

          })
        }

        it 'dispatches orders_package if exists with same designation' do
          package = create :package, :stockit_package, designation_name: 'abc',
            received_quantity: 1, quantity: 0
          orders_package = create :orders_package, package: package, order: order,
            state: 'designated', quantity: 1
          stockit_params_with_sent_on_and_designation[:stockit_id] = package.reload.stockit_id
           expect{
            post :create, format: :json, package: stockit_params_with_sent_on_and_designation
          }.to change(OrdersPackage, :count).by(0)
          test_package_changes(package, response.status, order.code, dispatched_location)
          expect(package.orders_packages.first.state).to eq 'dispatched'
          test_packages_location_changes(package)
          expect(package.reload.stockit_sent_by_id).to eq(stockit_user.id)
          expect(package.packages_locations.first.reference_to_orders_package).to eq orders_package.id
        end

        it 'creates new desigantion and then dispatch if package is not designated before dispatch from stockit' do
          package = create :package, :stockit_package, designation_name: 'abc', quantity: 1, received_quantity: 1
          stockit_params_with_sent_on_and_designation[:stockit_id] = package.reload.stockit_id
          stockit_params_with_sent_on_and_designation[:quantity] = 1

          expect{
            post :create, format: :json, package: stockit_params_with_sent_on_and_designation
          }.to change(OrdersPackage, :count).by(1)
          test_package_changes(package, response.status, order.code, dispatched_location)
          expect(package.orders_packages.first.state).to eq 'dispatched'
          expect(package.orders_packages.first.quantity).to eq 1
          expect(package.reload.quantity).to eq 0
          expect(package.reload.stockit_designated_by_id).to eq(stockit_user.id)
          expect(package.reload.stockit_sent_by_id).to eq(stockit_user.id)
          expect(package.reload.orders_packages.count).to eq 1
          test_packages_location_changes(package)
        end

        it 'updates existing designation with new order_id and dispatches it when dispatched from stockit with another order' do
          package = create :package, :stockit_package, designation_name: 'abc'
          orders_package = create :orders_package, package: package, order: order_1, state: 'designated'
          stockit_params_with_sent_on_and_designation[:stockit_id] = package.reload.stockit_id
          expect{
            post :create, format: :json, package: stockit_params_with_sent_on_and_designation
          }.to change(OrdersPackage, :count).by(0)
          test_package_changes(package, response.status, order.code, dispatched_location)
          expect(package.reload.stockit_designated_by_id).to eq(stockit_user.id)
          expect(package.reload.stockit_sent_by_id).to eq(stockit_user.id)
          expect(orders_package.reload.state).to eq 'dispatched'
          test_packages_location_changes(package)
        end

        it 'dispatches existing designation if available with same order_id' do
          package          = create :package, :stockit_package, quantity: 0
          orders_package = create :orders_package, :with_state_designated,
            package: package, order: order, quantity: 1
          stockit_params_with_sent_on_and_designation[:stockit_id] = package.reload.stockit_id
          stockit_params_with_sent_on_and_designation[:quantity]   = 1
          expect{
            post :create, format: :json, package: stockit_params_with_sent_on_and_designation
          }.to change(OrdersPackage, :count).by(0)
          test_package_changes(package, response.status, order.code, dispatched_location)
          expect(orders_package.reload.state).to eq 'dispatched'
          test_packages_location_changes(package)
        end

        it 'undispatches orders_package with matching order_id when Undispatch request from stockit.' do
          package = create :package, :stockit_package, stockit_sent_on: Date.today,
            order_id: order.id, received_quantity: 1, stockit_designated_by: stockit_user,
            quantity: 0
          orders_package = create :orders_package, package: package,
            order: order, state: 'dispatched', sent_on: Date.today, quantity: 1
          packages_location = create :packages_location, package: package, location_id: dispatched_location.id,
            quantity: 1, reference_to_orders_package: orders_package.id
          stockit_params_without_sent_on[:stockit_id] = package.reload.stockit_id
          stockit_params_without_sent_on[:location_id] = dispatched_location.stockit_id
          expect{
            post :create, format: :json, package: stockit_params_without_sent_on
          }.to change(OrdersPackage, :count).by(0)
          test_package_changes(package, response.status, order.code, dispatched_location)
          expect(orders_package.reload.state).to eq 'designated'
          expect(package.reload.stockit_designated_by_id).to eq(stockit_user.id)
          expect(package.reload.stockit_sent_by_id).to be_nil
          expect(orders_package.order_id).to eq order.id
          test_packages_location_changes(package)
        end
      end
    end
  end


  describe "PUT package/1" do
   before { generate_and_set_token(user) }
    it "reviewer can update", :show_in_doc do
      updated_params = { quantity: 30, width: 100 }
      put :update, format: :json, id: package.id, package: package_params.merge(updated_params)
      expect(response.status).to eq(200)
    end

    it "add stockit item-update request" do
      package = create :package, :received
      updated_params = { quantity: 30, width: 100, state: "received" }
      # expect(StockitUpdateJob).to receive(:perform_later).with(package.id)
      put :update, format: :json, id: package.id, package: package_params.merge(updated_params)
    end

  end

  describe "DELETE package/1" do
    before { generate_and_set_token(user) }

    it "returns 200", :show_in_doc do
      delete :destroy, id: package.id
      expect(response.status).to eq(200)
      expect(subject).to eq( {} )
    end

    it "should send delete-item request to stockit if package has inventory_number" do
      delete :destroy, id: (create :package, :stockit_package).id
      expect(response.status).to eq(200)
      expect(subject).to eq( {} )
    end
  end

  describe "POST print_barcode" do
    before { generate_and_set_token(user) }
    let(:inventory_number) {"000055"}
    let(:package) { create :package }
    let(:barcode_service) { BarcodeService.new }
    before(:each) {
      allow(barcode_service).to receive(:print).and_return(["", "", "pid 111 exit 0"])
      allow(controller).to receive(:barcode_service).and_return(barcode_service)
    }

    it "returns 400 if package does not exist" do
      post :print_barcode, package_id: 1, labels:1
      expect(response.status).to eq(400)
      expect(subject["errors"]).to eq("Package not found with supplied package_id")
    end

    it "should generate inventory number if empty on package" do
      expect(package.inventory_number).to be_blank
      post :print_barcode, package_id: package.id, labels:1
      package.reload
      expect(package.inventory_number).not_to be_blank
    end

    it "should print barcode service call with inventory number" do
      package.inventory_number = inventory_number
      package.save
      expect(barcode_service).to receive(:print).with(inventory_number, labels=1).and_return(["pid 111 exit 0", "", ""])
      post :print_barcode, package_id: package.id, labels: 1
    end

    it "return 200 status" do
      post :print_barcode, package_id: package.id, labels:1
      expect(response.status).to eq(200)
    end

    it "returns 400 if labels quantity is more than 300" do
      post :print_barcode, package_id: package.id, labels:301
      expect(response.status).to eq(400)
      expect(subject["errors"]).to eq("Print value should be between 0 and #{MAX_BARCODE_PRINT}.")
    end
  end

  describe "Items search" do
    before { generate_and_set_token(user) }
    it 'should find items by inventory number' do
      create :package, received_quantity: 1, inventory_number: "456222"
      create :package, received_quantity: 1, inventory_number: "456111"
      create :package, received_quantity: 1, inventory_number: "111111"
      create :package, received_quantity: 2, inventory_number: "456333"
      get :search_stockit_items, searchText: "456"
      expect(response.status).to eq(200)
      expect(subject['meta']['search']).to eql("456")
      expect(subject['items'].map{|i| i['inventory_number']}).to match_array(['456222', '456111', '456333'])
    end

    it 'should find items by inventory number (includes quantity items)' do
      create :package, received_quantity: 1, inventory_number: "456333"
      create :package, received_quantity: 2, inventory_number: "456222"
      create :package, received_quantity: 2, inventory_number: "456111"
      get :search_stockit_items, searchText: "456", showQuantityItems: 'true'
      expect(response.status).to eq(200)
      expect(subject['meta']['search']).to eql("456")
      expect(subject['items'].map{|i| i['inventory_number']}).to match_array(['456222', '456111', '456333'])
    end

    it 'should find items by notes' do
      create :package, received_quantity: 1, notes: "butter"
      create :package, received_quantity: 1, notes: "butterfly"
      create :package, received_quantity: 1, notes: "margarine"
      get :search_stockit_items, searchText: "UTter", showQuantityItems: 'true'
      expect(response.status).to eq(200)
      expect(subject['meta']['search']).to eql("UTter")
      expect(subject['items'].map{|i| i['notes']}).to match_array(['butter', 'butterfly'])
    end

    it 'should find items by case number' do
      create :package, received_quantity: 1, case_number: "CAS-123"
      create :package, received_quantity: 1, case_number: "CAS-124"
      create :package, received_quantity: 1, case_number: "CAS-666"
      get :search_stockit_items, searchText: "cas-12", showQuantityItems: 'true'
      expect(response.status).to eq(200)
      expect(subject['meta']['search']).to eql("cas-12")
      expect(subject['items'].map{|i| i['case_number']}).to match_array(['CAS-123', 'CAS-124'])
    end

    it 'should find items by designation_name' do
      create :package, received_quantity: 1, designation_name: "pepper"
      create :package, received_quantity: 1, designation_name: "peppermint"
      create :package, received_quantity: 1, designation_name: "garlic"
      get :search_stockit_items, searchText: "peP", showQuantityItems: 'true'
      expect(response.status).to eq(200)
      expect(subject['meta']['search']).to eql("peP")
      expect(subject['items'].map{|i| i['designation_name']}).to match_array(['pepper', 'peppermint'])
    end

    it 'should use filters to only find items that have an inventory number and are marked as received' do
      create :package, received_quantity: 1, designation_name: "couch", inventory_number: '11111', state: 'received'
      create :package, received_quantity: 1, designation_name: "couch", inventory_number: '22222', state: 'missing'
      create :package, received_quantity: 1, designation_name: "couch", inventory_number: nil, state: 'received'
      create :package, received_quantity: 1, designation_name: "couch", inventory_number: nil, state: 'missing'
      get :search_stockit_items, searchText: 'couch', showQuantityItems: 'true', state: 'received', withInventoryNumber: 'true'
      expect(response.status).to eq(200)
      expect(subject['meta']['search']).to eql('couch')
      expect(subject['items'].map{|i| i['inventory_number']}).to match_array(['11111'])

    end

    it 'should filter out item with published, has_images, and in_stock status' do
      create :package, inventory_number: "111000", state: 'received', quantity: 1
      create :package, inventory_number: "111001", state: 'received', allow_web_publish: true, quantity: 1
      create(:package, :with_images, inventory_number: "111005", allow_web_publish: true, state: 'received', quantity: 1)
      params = {
        searchText: '111',
        showQuantityItems: 'true',
        withInventoryNumber: 'true',
        state:'in_stock,published,has_images'
      }
      get :search_stockit_items, params
      expect(response.status).to eq(200)
      expect(subject['meta']['search']).to eql('111')
      expect(subject['items'].map{|i| i['inventory_number']}).to match_array(['111005'])

    end

    it "filter out multiquantity items if params has restrictMultiQuantity field" do
      create :package, inventory_number: "111000", quantity: 1
      create :package, inventory_number: "111001", quantity: 8
      create :package, inventory_number: "111005", quantity: 1
      params = {
        searchText: '111',
        stockRequest: true,
        restrictMultiQuantity: 'true',
        withInventoryNumber: 'true'
      }
      get :search_stockit_items, params
      expect(response.status).to eq(200)
      expect(subject["items"].count).to eq(2)
    end

    it "find multiquantity items if params does not have restrictMultiQuantity field" do
      create :package, inventory_number: "111000", quantity: 1
      create :package, inventory_number: "111001", quantity: 8
      create :package, inventory_number: "111005", quantity: 1
      params = {
        searchText: '111',
        stockRequest: true,
        withInventoryNumber: 'true'

      }
      get :search_stockit_items, params
      expect(response.status).to eq(200)
      expect(subject["items"].count).to eq(3)
    end

    it "search single quantity item created after Splitting of package" do
      create(:package, inventory_number: "F00001Q1", quantity: 2)
      create(:package, inventory_number: "F00001Q2", quantity: 2)
      create(:package, inventory_number: "F00001Q3", quantity: 1)
      params = {
        searchText: 'F00001Q',
        stockRequest: true,
        restrictMultiQuantity: 'true',
        withInventoryNumber: 'true'
      }
      get :search_stockit_items, params
      expect(response.status).to eq(200)
      expect(subject["items"].count).to eq(1)
    end

    it "response should have total_pages, and search in meta data" do
      create(:package, inventory_number: "F00001Q1")
      create(:package, inventory_number: "F00001Q2")
      create(:package, inventory_number: "F00001Q3")
      searchText = 'F00001Q'
      params = {
        searchText: searchText,
        stockRequest: true,
        restrictMultiQuantity: 'true',
        withInventoryNumber: 'true',
        page:1,
        per_page:25
      }
      get :search_stockit_items, params
      expect(subject["meta"]["search"]).to eq(searchText)
      expect(subject["meta"].keys).to include("total_pages")
    end
  end
end
