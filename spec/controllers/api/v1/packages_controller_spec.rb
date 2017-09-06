require "rails_helper"

RSpec.describe Api::V1::PackagesController, type: :controller do

  let(:user) { create(:user_with_token, :reviewer) }
  let(:donor) { create(:user_with_token) }
  let(:offer) { create :offer, created_by: donor }
  let(:item)  { create :item, offer: offer }
  let(:package_type)  { create :package_type }
  let(:package) { create :package, item: item }
  let(:package_with_stockit_id) { create :package, :stockit_package, item: item }
  let(:orders_package) { create :orders_package, package: package, order: order_id }
  let(:serialized_package) { Api::V1::PackageSerializer.new(package) }
  let(:serialized_package_json) { JSON.parse( serialized_package.to_json ) }

  let(:package_params) do
    FactoryGirl.attributes_for(:package, item_id: "#{item.id}", package_type_id: "#{package_type.id}")
  end

  subject { JSON.parse(response.body) }

  def test_package_changes(package, response_status, designation_name)
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

  describe "GET packages for Item" do
   before { generate_and_set_token(user) }
    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end
    it "return serialized packages", :show_in_doc do
      3.times{ create :package }
      get :index
      body = JSON.parse(response.body)
      expect( body["packages"].size ).to eq(3)
    end
  end

 describe "PUT move_full_quantity" do
    before { generate_and_set_token(user) }

    before(:all) do
      Timecop.freeze('2013-04-24'.to_date) { Time.zone.now.to_date }
    end

    after(:all) do
      Timecop.return
    end

    let(:order) { create :order }
    let(:package) { create :package, order: order, stockit_sent_on: Time.zone.now.to_date }
     let(:dispatched_location) { create :location, :dispatched }
    let(:location_1) { create :location }
    let(:orders_package) { create :orders_package, package: package, order: order, state: 'dispatched' }
    let!(:packages_location) { create :packages_location, package: package,
      location: dispatched_location, reference_to_orders_package: orders_package.id}

    context 'undispatch from gc' do
      it 'undispatches orders_package with matching order_id when undispatched from gc and assigns locaion aginst package' do
        put :move_full_quantity, format: :json, location_id: location_1.id, ordersPackageId: orders_package.id, id: package.id
        expect(package.reload.locations).to include(location_1)
        expect(package.packages_locations.count).to eq 1
        expect(package.reload.order_id).to eq order.id
        expect(package.reload.stockit_sent_on).to eq nil
        expect(orders_package.reload.state).to eq 'designated'
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

    describe "Received from Stockit" do
      let(:location) { create :location }
      let!(:order) { create :order, :with_stockit_id }
      let(:order_1) { create :order, :with_stockit_id }
      let!(:code) { create :package_type, :with_stockit_id }
      let(:donor_condition) { create :donor_condition }
      let!(:location) { create :location, :dispatched }
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

        let(:stockit_item_params_with_designation){
          stockit_item_params.merge({
            designation_name: order.code,
            order_id: order.stockit_id
          })
        }

        let(:stockit_item_params_without_designation){
          stockit_item_params.merge({
            designation_name: '',
            order_id: nil,
            stockit_id: package_with_stockit_id.stockit_id
          })
        }

        it "create new package with designation for newly created item from stockit with designation", :show_in_doc do
          expect{
            post :create, format: :json, package: stockit_item_params_with_designation
          }.to change(Package, :count).by(1)
          package = Package.where(inventory_number: stockit_item_params_with_designation[:inventory_number]).first
          test_package_changes(package, response.status, order.code)
          stockit_request = GoodcitySync.request_from_stockit
          test_orders_packages(package, stockit_request, 1)
          expect(package.orders_packages.first.state).to eq 'designated'
          expect(package.orders_packages.first.quantity).to eq 1
          expect(package.quantity).to eq(0)
        end

        it 'do not creates any orders_package if designation name was nil and not changed' do
          expect{
            post :create, format: :json, package: stockit_item_params_without_designation
          }.to change(OrdersPackage, :count).by(0)
          test_package_changes(package_with_stockit_id, response.status, '')
          stockit_request = GoodcitySync.request_from_stockit
          test_orders_packages(package, stockit_request, 0)
        end

        it 'creates orders_package for already existing item which is now designated from stockit' do
          package = create :package, :stockit_package, item: item
          stockit_item_params_with_designation[:stockit_id] = package.stockit_id
          expect{
            post :create, format: :json, package: stockit_item_params_with_designation
          }.to change(OrdersPackage, :count).by(1)
          test_package_changes(package, response.status, order.code)
          stockit_request = GoodcitySync.request_from_stockit
          test_orders_packages(package, stockit_request, 1)
        end

        it 'updates designation if item has designation in stockit and then designated to some other designation' do
          package = create :package, :stockit_package, item: item
          order1 = create :order
          orders_package = create :orders_package, :with_state_designated, order: order1, package: package
          stockit_item_params_with_designation[:stockit_id] = package.stockit_id
          expect{
            post :create, format: :json, package: stockit_item_params_with_designation
          }.to change(OrdersPackage, :count).by(0)
          test_package_changes(package, response.status, order.code)
          stockit_request = GoodcitySync.request_from_stockit
          test_orders_packages(package, stockit_request, 1)
          expect(package.orders_packages.first.order).to eq order
          expect(package.orders_packages.first.state).to eq 'designated'
        end

        it 'cancels designation if item was previously designated and now its undesignated from stockit' do
          package = create :package, :stockit_package, designation_name: 'abc', order: order
          orders_package = create :orders_package, :with_state_designated, order: order, package: package
          stockit_item_params_without_designation[:stockit_id] = package.reload.stockit_id
          expect{
            post :create, format: :json, package: stockit_item_params_without_designation
          }.to change(OrdersPackage, :count).by(0)
          test_package_changes(package, response.status, '')
          stockit_request = GoodcitySync.request_from_stockit
          test_orders_packages(package, stockit_request, 1)
          expect(orders_package.state).to eq('cancelled')
        end

        it 'updates cancelled orders_package to designated if item designated to existing cancelled orders_package' do
          package = create :package, :stockit_package, designation_name: 'abc'
          orders_package = create :orders_package, :with_state_cancelled, order: order, package: package
          stockit_item_params_with_designation[:stockit_id] = package.reload.stockit_id
          expect{
            post :create, format: :json, package: stockit_item_params_with_designation
          }.to change(OrdersPackage, :count).by(0)
          test_package_changes(package, response.status, order.code)
          stockit_request = GoodcitySync.request_from_stockit
          test_orders_packages(package, stockit_request, 1)
          expect(package.orders_packages.first.state).to eq('designated')
        end

        it 'designates item to cancelled designation if again designated to same and if it has another active designation with some other order_id then it cancels it' do
          package = create :package, :stockit_package, designation_name: 'abc'
          orders_package = create :orders_package, :with_state_cancelled, order: order, package: package
          orders_package_1 = create :orders_package, :with_state_designated, order: order_1, package: package
          stockit_item_params_with_designation[:stockit_id] = package.reload.stockit_id
          expect{
            post :create, format: :json, package: stockit_item_params_with_designation
          }.to change(OrdersPackage, :count).by(0)
          test_package_changes(package, response.status, order.code)
          expect(orders_package.reload.state).to eq 'designated'
          expect(orders_package_1.reload.state).to eq('cancelled')
          expect(GoodcitySync.request_from_stockit).to eq(true)
        end
      end

      context 'Dispatch & Undispatch from stockit' do
        let(:stockit_params_with_sent_on_and_designation){
          stockit_item_params.merge({
            stockit_sent_on: Date.today,
            designation_name: order.code,
            order_id: order.stockit_id
          })
        }

        let(:stockit_params_without_sent_on){
          stockit_item_params.merge({
            stockit_sent_on: '',
            designation_name: order.code,
            order_id: order.stockit_id
          })
        }

        it 'dispatches orders_package if exists with same designation' do
          package = create :package, :with_inventory_number, stockit_id: 5, designation_name: 'abc'
          orders_package = create :orders_package, package: package, order: order, state: 'designated'
          packages_location = create :packages_location, package: package,
            location: location, reference_to_orders_package: orders_package.id
          stockit_params_with_sent_on_and_designation[:stockit_id] = package.reload.stockit_id
          expect{
            post :create, format: :json, package: stockit_params_with_sent_on_and_designation
          }.to change(OrdersPackage, :count).by(0)
          test_package_changes(package, response.status, order.code)
          expect(package.locations.first).to eq(location)
          expect(package.orders_packages.first.state).to eq 'dispatched'
          test_packages_location_changes(package)
          expect(package.packages_locations.first.reference_to_orders_package).to eq orders_package.id
        end

        it 'creates new desigantion and then dispatch if package is not designated before dispatch from stockit' do
          package = create :package, :stockit_package, designation_name: 'abc', quantity: 1
          stockit_params_with_sent_on_and_designation[:stockit_id] = package.reload.stockit_id
          stockit_params_with_sent_on_and_designation[:quantity] = 1
          expect{
            post :create, format: :json, package: stockit_params_with_sent_on_and_designation
          }.to change(OrdersPackage, :count).by(1)
          test_package_changes(package, response.status, order.code)
          expect(package.orders_packages.first.state).to eq 'dispatched'
          expect(package.orders_packages.first.quantity).to eq 1
          expect(package.reload.quantity).to eq 0
          expect(package.reload.orders_packages.count).to eq 1
          test_packages_location_changes(package)
        end

        it 'cancels designation and creates new orders_package with state dispatched if dispatched with another designation from stockit' do
          package = create :package, :stockit_package, designation_name: 'abc'
          orders_package = create :orders_package, package: package, order: order_1, state: 'designated'
          stockit_params_with_sent_on_and_designation[:stockit_id] = package.reload.stockit_id
          expect{
            post :create, format: :json, package: stockit_params_with_sent_on_and_designation
          }.to change(OrdersPackage, :count).by(1)
          test_package_changes(package, response.status, order.code)
          expect(orders_package.reload.state).to eq 'cancelled'
          test_packages_location_changes(package)
        end

        it 'cancels existing designation and dispatches orders_package if available with same order id' do
          package          = create :package, :stockit_package, quantity: 0
          orders_package   = create :orders_package, :with_state_designated,
            package: package, order: order_1, quantity: 1
          orders_package_1 = create :orders_package, :with_state_cancelled,
            package: package, order: order, quantity: 0
          stockit_params_with_sent_on_and_designation[:stockit_id] = package.reload.stockit_id
          stockit_params_with_sent_on_and_designation[:quantity]   = 1
          expect{
            post :create, format: :json, package: stockit_params_with_sent_on_and_designation
          }.to change(OrdersPackage, :count).by(0)
          test_package_changes(package, response.status, order.code)
          expect(orders_package.reload.quantity).to eq 0
          expect(orders_package.reload.state).to eq 'cancelled'
          expect(orders_package_1.reload.quantity).to eq 1
          expect(orders_package_1.state).to eq 'dispatched'
          test_packages_location_changes(package)
        end

        it 'undispatches orders_package with matching order_id when Undispatch request from stockit.' do
          package = create :package, :stockit_package, stockit_sent_on: Date.today, order_id: order.id
          orders_package = create :orders_package, package: package,
            order: order, state: 'dispatched', sent_on: Date.today
          stockit_params_without_sent_on[:stockit_id] = package.reload.stockit_id
          expect{
            post :create, format: :json, package: stockit_params_without_sent_on
          }.to change(OrdersPackage, :count).by(0)
          test_package_changes(package, response.status, order.code)
          expect(orders_package.reload.state).to eq 'designated'
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
      body = JSON.parse(response.body)
      expect(body).to eq( {} )
    end

    it "should send delete-item request to stockit if package has inventory_number" do
      delete :destroy, id: (create :package, :stockit_package).id
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body).to eq( {} )
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
      post :print_barcode, package_id: 1
      expect(response.status).to eq(400)
      body = JSON.parse(response.body)
      expect(body["errors"]).to eq("Package not found with supplied package_id")
    end

    it "should generate inventory number if empty on package" do
      expect(package.inventory_number).to be_blank
      post :print_barcode, package_id: package.id
      package.reload
      expect(package.inventory_number).not_to be_blank
    end

    it "should print barcode service call with inventory number" do
      package.inventory_number = inventory_number
      package.save
      expect(barcode_service).to receive(:print).with(inventory_number).and_return(["pid 111 exit 0", "", ""])
      post :print_barcode, package_id: package.id
    end

    it "return 200 status" do
      post :print_barcode, package_id: package.id
      expect(response.status).to eq(200)
    end
  end
end
