require "rails_helper"

RSpec.describe Api::V1::PackagesController, type: :controller do
  let(:supervisor) { create(:user, :supervisor, :with_can_manage_packages_permission )}
  let(:user) { create(:user, :with_token, :with_reviewer_role, :with_can_manage_packages_permission, :with_can_manage_orders_permission) }
  let!(:stockit_user) { create(:user, :stockit_user, :api_write)}
  let(:donor) { create(:user, :with_token) }
  let(:offer) { create :offer, created_by: donor }
  let(:item)  { create :item, offer: offer }
  let(:package_type)  { create :package_type }
  let(:package) { create :package, :with_inventory_record, item: item }
  let(:package_with_stockit_id) { create :package, :with_inventory_record, :stockit_package, item: item }
  let(:orders_package) { create :orders_package, package: package }
  let(:serialized_package) { Api::V1::PackageSerializer.new(package).as_json }
  let(:serialized_package_json) { JSON.parse( serialized_package.to_json ) }
  let(:parsed_body) { JSON.parse(response.body) }
  let(:response_packages) { parsed_body['packages'].map { |p| Package.find(p['id'])} }
  let(:error_msg) do
    return parsed_body['error'] if parsed_body['error'].present?
    parsed_body['errors'][0]['message']
  end

  let(:package_params) do
    FactoryBot
      .attributes_for(:package, item_id: "#{item.id}", package_type_id: "#{package_type.id}")
      .except(:dispatched_quantity, :available_quantity, :on_hand_quantity, :designated_quantity)
      .merge({ quantity: 5 })
  end

  subject { JSON.parse(response.body) }

  def test_package_changes(package, response_status, designation_name, location)
    expect(package.reload.designation_name).to eq(designation_name)
    expect(package.locations.try(:first)).to eq(location)
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
    context 'as a user' do
      before { generate_and_set_token(user) }
      it "returns 200" do
        get :index
        expect(response.status).to eq(200)
      end

      it "return serialized packages", :show_in_doc do
        3.times{ create :package, :with_inventory_record }
        get :index
        expect( subject["packages"].size ).to eq(3)
      end

      it "returns searched packages" do
        set_browse_app_header
        3.times{ create :package, :with_inventory_record, notes: "Baby towels", allow_web_publish: false }
        3.times{ create :browseable_package, :with_inventory_record, notes: "Baby car seats" }
        expect(Package.count).to eq(6)
        get :index, params: { "searchText": "car" }
        expect(response.status).to eq(200)
        expect( subject["packages"].size ).to eq(3)
      end

      it "returns packages by inventory numbers" do
        p1, p2, p3 = ['111111', '1111112', '111113'].map { |n| create(:package, :with_inventory_record, inventory_number: n) }
        initialize_inventory(p1, p2, p3)

        expect(Package.count).to eq(3)
        get :index, params: { "inventory_number": "111111,1111112" }
        expect(response.status).to eq(200)
        expect( response_packages ).to match_array([p1,p2])
      end

      it "returns searched browseable_packages only" do
        set_browse_app_header
        3.times{ create :package, :with_inventory_record, notes: "Baby towels", allow_web_publish: false }
        3.times{ create :browseable_package, :with_inventory_record, notes: "Baby car seats" }
        create :browseable_package, :with_inventory_record, notes: "towels"
        expect(Package.count).to eq(7)
        get :index, params: { "searchText": "towel" }
        expect(response.status).to eq(200)
        expect( subject["packages"].size ).to eq(1)
      end
    end

    context "as an anonymous user" do
      before { request.headers['Authorization'] = nil }

      it "should allow fetching a published package" do
        published_package = create :package, :published
        get :show, params: { id: published_package.id }
        expect(response.status).to eq(200)
      end

      it "should prevent fetching an unpublished package" do
        published_package = create :package, :unpublished
        get :show, params: { id: published_package.id }
        expect(response.status).to eq(403)
      end

      it "returns searched packages" do
        set_browse_app_header
        3.times{ create :package, :with_inventory_record, notes: "Baby towels", allow_web_publish: false }
        3.times{ create :browseable_package, :with_inventory_record, notes: "Baby Toilets" }
        expect(Package.count).to eq(6)
        get :index, params: { "searchText": "Baby" }
        expect(response.status).to eq(200)
        expect( subject["packages"].size ).to eq(3)
      end

      it "returns searched browseable_packages only" do
        set_browse_app_header
        3.times{ create :package, :with_inventory_record, notes: "Baby towels", allow_web_publish: false }
        3.times{ create :browseable_package, :with_inventory_record, notes: "Baby car seats" }
        create :browseable_package, :with_inventory_record, notes: "towels"
        expect(Package.count).to eq(7)
        get :index, params: { "searchText": "towel" }
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
        get :show, params: { id: published_package.id }
        expect(response.status).to eq(200)
      end

      it "should prevent fetching an unpublished package" do
        published_package = create :package, :unpublished
        get :show, params: { id: published_package.id }
        expect(response.status).to eq(403)
      end
    end

    context "as a supervisor" do
      before { generate_and_set_token(supervisor) }

      it "should allow fetching a published package" do
        published_package = create :package, :published
        get :show, params: { id: published_package.id }
        expect(response.status).to eq(200)
      end

      it "should allow fetching an unpublished package" do
        published_package = create :package, :unpublished
        get :show, params: { id: published_package.id }
        expect(response.status).to eq(200)
      end
    end
  end

  describe "Marking a package as missing (PUT /:id/mark_missing)" do
    let(:order) { create :order, :with_state_submitted }
    let(:package) { create :package, :with_inventory_record, received_quantity: 5, state: "received" }
    let(:location) { package.locations.first }

    before do
      generate_and_set_token(user)
      allow(Stockit::ItemSync).to receive(:delete)
    end

    it 'adds an uninventory action to the packages_inventory' do
      expect {
        put :mark_missing, params: { id: package.id }
      }.to change { PackagesInventory.inventorized?(package) }.from(true).to(false)

      expect(response.status).to eq(200)
    end

    it 'sets the state to missing' do
      expect {
        put :mark_missing, params: { id: package.id }
      }.to change { package.reload.state }.from('received').to('missing')

      expect(response.status).to eq(200)
    end

    it 'zeroes the on_hand_quantity' do
      expect {
        put :mark_missing, params: { id: package.id }
      }.to change { package.reload.on_hand_quantity }.from(5).to(0)

      expect(response.status).to eq(200)
      expect(parsed_body["package"]["on_hand_quantity"]).to eq(0)
    end

    it 'zeroes the available_quantity' do
      expect {
        put :mark_missing, params: { id: package.id }
      }.to change { package.reload.available_quantity }.from(5).to(0)

      expect(response.status).to eq(200)
      expect(parsed_body["package"]["available_quantity"]).to eq(0)
    end

    it 'fails if the inventory has been modified' do
      Package::Operations.register_loss(package, quantity: 1, location: location)

      expect {
        put :mark_missing, params: { id: package.id }
      }.not_to change { package.reload.state }

      expect(response.status).to eq(422)
      expect(parsed_body['error']).to eq("Package cannot be uninventorized")
    end
  end

  describe "Designating the package (PUT /:id/designate)" do
    let(:location) { create :location }
    let(:order) { create :order, :with_state_submitted }
    let(:package) { create :package, :with_inventory_number, received_quantity: 5 }
    let(:uninventorized_package) { create :package, inventory_number: nil }

    before do
      # Initialize stock quantity
      create(:packages_inventory, action: 'inventory', package: package, location: location, quantity: package.received_quantity)
      generate_and_set_token(user)
    end

    it 'fails to designate an uninventorized package' do
      expect(Stockit::OrdersPackageSync).not_to receive(:create)

      put :designate, params: { id: uninventorized_package.id, quantity: 5, order_id: order.id }

      expect(response.status).to eq(422)
      expect(parsed_body["error"]).to eq("Cannot operate on uninventorized packages")
    end

    it 'designates the entire quantity to the order' do
      allow(Stockit::OrdersPackageSync).to receive(:create)

      expect {
        put :designate, params: { id: package.id, quantity: 5, order_id: order.id }
      }.to change { package.reload.orders_packages.count }.from(0).to(1)

      expect(response.status).to eq(200)
      expect(package.orders_packages.first).to have_attributes(:quantity => 5, :order_id => order.id, :package_id => package.id)
      expect(PackagesInventory::Computer.available_quantity_of(package)).to eq(0)
    end

    it 'designates the part of the quantity to the order' do
      allow(Stockit::OrdersPackageSync).to receive(:create)

      expect {
        put :designate, params: { id: package.id, quantity: 2, order_id: order.id }
      }.to change { package.reload.orders_packages.count }.from(0).to(1)

      expect(response.status).to eq(200)
      expect(package.orders_packages.first).to have_attributes(:quantity => 2, :order_id => order.id, :package_id => package.id)
      expect(PackagesInventory::Computer.available_quantity_of(package)).to eq(3)
    end

    it 'updates an existing designation' do
      allow(Stockit::OrdersPackageSync).to receive(:create)
      allow(Stockit::OrdersPackageSync).to receive(:update)

      Package::Operations.designate(package, quantity: 3, to_order: order)

      expect(PackagesInventory::Computer.available_quantity_of(package)).to eq(2)
      expect(package.reload.orders_packages.count).to eq(1)

      expect {
        put :designate, params: { id: package.id, quantity: 5, order_id: order.id }
      }.to change { package.reload.orders_packages.first.quantity }.from(3).to(5)

      expect(response.status).to eq(200)
      expect(package.reload.orders_packages.count).to eq(1)
      expect(PackagesInventory::Computer.available_quantity_of(package)).to eq(0)
    end

    context 'with bad parameters' do
      it 'fails if the order_id is bad' do
        put :designate, params: { id: package.id, quantity: 5, order_id: 'i.dont.exist' }
        expect(response.status).to eq(404)
        expect(error_msg).to match(/^Couldn't find Order/)
      end

      it 'fails if the package_id is bad' do
        put :designate, params: { id: 'i.dont.exist', quantity: 5, order_id: order.id }
        expect(response.status).to eq(404)
        expect(error_msg).to match(/^Couldn't find Package/)
      end

      it 'fails if the quantity is bad' do
        put :designate, params: { id: package.id, quantity: -5, order_id: order.id }
        expect(response.status).to eq(422)
        expect(error_msg).to match(/^Invalid quantity/)
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
      allow(Stockit::ItemSync).to receive(:move)
      expect(package.packages_locations.length).to eq(1)
      expect(package.packages_locations.first.location).to eq(location1)
      expect(package.packages_locations.first.quantity).to eq(5)

      put :move, params: { id: package.id, quantity: 5, from: location1.id, to: location2.id }

      expect(response.status).to eq(200)

      package.reload
      expect(package.packages_locations.length).to eq(1)
      expect(package.packages_locations.first.location).to eq(location2)
      expect(package.packages_locations.first.quantity).to eq(5)
    end

    it 'moves part of the quantity to the desired location' do
      expect(package.packages_locations.length).to eq(1)
      expect(package.packages_locations.first.location).to eq(location1)
      expect(package.packages_locations.first.quantity).to eq(5)

      put :move, params: { id: package.id, quantity: 3, from: location1.id, to: location2.id }

      expect(response.status).to eq(200)

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

      put :move, params: { id: package.id, quantity: 3, from: location1.id, to: location2.id }

      expect(response.status).to eq(200)

      package.reload
      expect(package.packages_locations.length).to eq(2)
      expect(package.packages_locations.first.location).to eq(location1)
      expect(package.packages_locations.first.quantity).to eq(2)
      expect(package.packages_locations.last.location).to eq(location2)
      expect(package.packages_locations.last.quantity).to eq(4)
    end

    context 'with bad parameters' do
      it 'fails if the from location is missing' do
        put :move, params: { id: package.id, quantity: 3, to: location2.id }
        expect(response.status).to eq(404)
        expect(error_msg).to match(/^Couldn't find Location/)
      end

      it 'fails if the to location is missing' do
        put :move, params: { id: package.id, quantity: 3, from: location2.id }
        expect(response.status).to eq(404)
        expect(error_msg).to match(/^Couldn't find Location/)
      end

      it 'fails if the the package_id is wrong' do
        put :move, params: { id: '9999', from: location2.id }
        expect(response.status).to eq(404)
        expect(error_msg).to match(/^Couldn't find Package with 'id'=9999/)
      end

      it 'fails if the quantity is missing' do
        put :move, params: { id: package.id, from: location2.id }
        expect(response.status).to eq(422)
        expect(error_msg).to match(/^Invalid quantity/)
      end
    end
  end

  describe "POST package/1" do
    let(:location) { create(:location) }

    before { generate_and_set_token(user) }

    context "create package from gc" do
      let(:created_package_id) { parsed_body['package']['id'] }
      let(:created_package) { Package.find(created_package_id) }

      it "reviewer can create", :show_in_doc do
        post :create, params: { package: package_params }
        expect(response.status).to eq(201)
        expect(GoodcitySync.request_from_stockit).to eq(false)
      end

      context 'when saleable value is provided in package parameters' do
        it 'creates package record with given saleable value' do
          [true, false].map do |val|
            package_params[:saleable] = val
            package_params[:item_id] = nil
            post :create, params: { package: package_params }
            expect(response).to have_http_status(:success)
            package_id = parsed_body['package']['id']
            package = Package.find(package_id)
            expect(package.saleable).to eq(val)
          end
        end

        context 'if package has an associated offer' do
          context 'if offer is not saleable' do
            [true, false].map do |val|
              it "creates package with saleble value #{val}" do
                item.offer.update(saleable: false)
                package_params[:saleable] = val
                post :create, params: { package: package_params }
                expect(response).to have_http_status(:success)
                package_id = parsed_body["package"]["id"]
                package = Package.find(package_id)
                expect(package.saleable).to eq(val)
              end
            end
          end

          context 'if offer is saleable' do
            [true, false].map do |val|
              it 'creates package with saleable as true' do
                item.offer.update(saleable: true)
                package_params[:saleable] = val
                post :create, params: { package: package_params }
                expect(response).to have_http_status(:success)
                package_id = parsed_body["package"]["id"]
                package = Package.find(package_id)
                expect(package.saleable).to eq(true)
              end
            end
          end
        end
      end

      it 'creates package record with value_hk_dollar' do
        package_params[:value_hk_dollar] = 20
        post :create, params: { package: package_params }
        package = Package.find(parsed_body['package']['id'])
        expect(package.value_hk_dollar).to eq(package_params[:value_hk_dollar])
      end

      context 'if value_hk_dollar is nil' do
        it 'sets a default value' do
          package_params[:value_hk_dollar] = nil
          post :create, params: { package: package_params }
          package = Package.find(parsed_body["package"]["id"])
          expect(package.value_hk_dollar).not_to be_nil
        end
      end

      context "without an inventory_number" do
        context "but with a location" do
          before { package_params[:location_id] = location.id }

          it "creates a package with no packages_location (location_id is ignored)" do
            post :create, params: { package: package_params }
            expect(response.status).to eq(201)
            expect(created_package.packages_locations.count).to eq(0)
          end

          it "creates a package with no packages_inventory record (location_id is ignored)" do
            post :create, params: { package: package_params }
            expect(response.status).to eq(201)
            expect(PackagesInventory.count).to eq(0)
          end
        end
      end

      context "with an inventory_number" do
        before { package_params[:inventory_number] = '98767' }

        context "and a location_id" do
          before { package_params[:location_id] = location.id }

          it "created a packages_inventory 'inventory' action row" do
            expect {
              post :create, params: { package: package_params }
            }.to change(PackagesInventory, :count).from(0).to(1)

            expect(PackagesInventory.last.package_id).to eq(created_package_id)
            expect(PackagesInventory.last.quantity).to eq(created_package.received_quantity)
            expect(PackagesInventory.last.location_id).to eq(location.id)
            expect(PackagesInventory.last.action).to eq('inventory')
          end

          it "creates the packages_locations relation (through packages_inventory sync)" do
            expect {
              post :create, params: { package: package_params }
            }.to change(PackagesLocation, :count).from(0).to(1)

            expect(response.status).to eq(201)
            expect(created_package.packages_locations.count).to eq(1)
            expect(created_package.packages_locations.first.location_id).to eq(location.id)
            expect(created_package.packages_locations.first.quantity).to eq(package.received_quantity)
          end
        end

        context "but no location_id" do
          it "fails to create the package" do
            expect {
              post :create, params: { package: package_params }
              expect(response.status).to eq(422)
              expect(parsed_body['error']).to match("Invalid or missing Location")
            }.not_to change(Package, :count)
          end
        end
      end

      context 'when inventory number is duplicate' do
        before { package_params[:location_id] = location.id }
        let(:package) { create(:package, :with_inventory_number) }

        context 'if STOCKIT is disabled' do
          before do
            stub_const('STOCKIT_ENABLED', false)
          end

          it 'does not allow creation of package with duplicate inventory number' do
            package_params[:inventory_number] = package.inventory_number
            expect {
              post :create, params: { package: package_params }
            }.to change(Package, :count).by(0)
          end

          it 'throws uniqueness constraint error for inventory number' do
            package_params[:inventory_number] = package.inventory_number
            post :create, params: { package: package_params }
            expect(parsed_body['errors']).to include('Inventory number has already been taken')
          end
        end

        context 'if STOCKIT is enabled' do
          before do
            stub_const('STOCKIT_ENABLED', true)
          end

          it 'does allow creation of package with duplicate inventory number' do
            package_params[:inventory_number] = package.inventory_number
            expect {
              post :create, params: { package: package_params }
            }.to change(Package, :count).by(1)
          end
        end

        after do
          stub_const('STOCKIT_ENABLED', true)
        end
      end
    end

    context "create package with storage type with creation of box/pallet setting enabled" do
      let!(:location) { create :location }
      let!(:code) { create :package_type, :with_stockit_id }
      let!(:box) { create :storage_type, :with_box }
      let!(:pallet) { create :storage_type, :with_pallet }
      let!(:pkg_storage) { create :storage_type, :with_pkg }
      let!(:setting) { create(:goodcity_setting, key: "stock.enable_box_pallet_creation", value: "true") }
      let!(:setting2) { create(:goodcity_setting, key: "stock.allow_box_pallet_item_addition", value: "true") }

      let(:stockit_item_params) {
        {
          quantity: 1,
          inventory_number: "123456",
          location_id: location.id,
          grade: "C",
          stockit_id: 1,
          code_id: code.stockit_id,
        }
      }
      let(:package_params){
        stockit_item_params.merge({
          quantity: 1,
          received_quantity: package.received_quantity,
          package_type_id:package.package_type_id,
          state: package.state,
          stockit_id: package.stockit_id,
          donor_condition_id: package.donor_condition_id,
          storage_type: "Package"
        })
      }

      describe "create with storage type box" do
        it "creates package with box storage type" do
          expect(GoodcitySetting.find_by(key: "stock.enable_box_pallet_creation").value).to eq(setting.value)
          package_params[:storage_type] = "Box"
          package_params[:received_quantity] = 1
          post :create, params: { package: package_params }
          expect(response.status).to eq(201)
          package = Package.last
          expect(parsed_body["package"]["id"]).to eq(package.id)
          expect(parsed_body["package"]["storage_type_id"]).to eq(package.storage_type_id)
        end
      end

      it "creates package with pallet storage type" do
        package_params[:storage_type] = "Pallet"
        package_params[:received_quantity] = 1
        post :create, params: { package: package_params }
        expect(response.status).to eq(201)
        package = Package.last
        expect(parsed_body["package"]["id"]).to eq(package.id)
        expect(parsed_body["package"]["storage_type_id"]).to eq(package.storage_type_id)
      end

      it "creates package with package storage type" do
        package_params[:storage_type] = "Package"
        post :create, params: { package: package_params }
        expect(response.status).to eq(201)
        package = Package.last
        expect(parsed_body["package"]["id"]).to eq(package.id)
        expect(parsed_body["package"]["storage_type_id"]).to eq(package.storage_type_id)
      end

      it 'has 0 on_hand_boxed_quantity as default' do
        package_params[:storage_type] = 'Box'
        package_params[:received_quantity] = 1
        post :create, params: { package: package_params }
        expect(parsed_body['package']['on_hand_boxed_quantity']).to eq(0)
      end

      it 'has 0 on_hand_palletized_quantity as default' do
        package_params[:storage_type] = 'Pallet'
        package_params[:received_quantity] = 1
        post :create, params: { package: package_params }
        expect(parsed_body['package']['on_hand_boxed_quantity']).to eq(0)
      end
    end

    context "should not create package with creation of box/pallet setting disabled" do
      let!(:location) { create :location }
      let!(:code) { create :package_type, :with_stockit_id }
      let!(:box) { create :storage_type, :with_box }
      let!(:pallet) { create :storage_type, :with_pallet }
      let!(:pkg_storage) { create :storage_type, :with_pkg }
      let!(:setting) { create(:goodcity_setting, key: "stock.enable_box_pallet_creation", value: "false") }
      let!(:setting1) { create(:goodcity_setting, key: "stock.allow_box_pallet_item_addition", value: "false") }

      let(:stockit_item_params) {
        {
          quantity: 1,
          inventory_number: "123456",
          location_id: location.stockit_id,
          grade: "C",
          stockit_id: 1,
          code_id: code.stockit_id,
        }
      }
      let(:package_params) {
        stockit_item_params.merge({
          quantity: 1,
          received_quantity: package.received_quantity,
          package_type_id: package.package_type_id,
          state: package.state,
          stockit_id: package.stockit_id,
          donor_condition_id: package.donor_condition_id,
          storage_type: "Package"
        })
      }

      describe "creation with setting false" do
        it "should not create package if setting is false" do
          expect(GoodcitySetting.enabled?("stock.enable_box_pallet_creation")).to eq(false)
          package_params[:storage_type] = "Box"
          post :create, params: { package: package_params }
          expect(response.status).to eq(422)
          expect(parsed_body["errors"]).to_not be_nil
          expect(parsed_body["errors"]).to eq(["Creation of box/pallet is not allowed."])
        end
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
          location_id: location.id,
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
          post :create, params: { package: package_params_with_details }
          expect(response.status).to eq(201)
          package = Package.last
          expect(parsed_body["package"]["id"]).to eq(package.id)
          expect(parsed_body["package"]["detail_type"]).to eq(package.detail_type)
          expect(parsed_body["package"]["detail_id"]).to eq(package.detail_id)
        end

        it "does not create package with detail if anything fails in package" do
          allow(Stockit::ItemDetailSync).to receive(:create).and_return({"status"=>201, "computer_id"=> 12})
          post :create, params: { package: package_params_with_details_incorrect_params }
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

      before { request.headers["X-GOODCITY-APP-NAME"] = STOCKIT_APP }

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

        before(:each) { initialize_inventory(package_with_stockit_id, location: location) }

        it "create new package with designation for newly created item from stockit with designation", :show_in_doc do
          expect{
            post :create, params: { package: stockit_item_params_with_designation }
          }.to change(Package, :count).by(1)
          package = Package.where(inventory_number: stockit_item_params_with_designation[:inventory_number]).first
          test_package_changes(package, response.status, order.code, location)
          stockit_request = GoodcitySync.request_from_stockit
          test_orders_packages(package, stockit_request, 1)
          expect(package.orders_packages.first.state).to eq 'designated'
          expect(package.orders_packages.first.quantity).to eq 1
          expect(PackagesInventory::Computer.package_quantity(package)).to eq(1)
          expect(PackagesInventory::Computer.available_quantity_of(package)).to eq(0)
          expect(package.reload.stockit_designated_by_id).to eq(stockit_user.id)
          expect(package.location_id).to eq location.id
        end

        it 'do not creates any orders_package if designation name was nil and not changed' do
          expect{
            post :create, params: { package: stockit_item_params_without_designation }
          }.to change(OrdersPackage, :count).by(0)
          expect(response.status).to eq(201)
          test_package_changes(package_with_stockit_id, response.status, '', location)
          stockit_request = GoodcitySync.request_from_stockit
          test_orders_packages(package, stockit_request, 0)
        end

        it 'creates orders_package for already existing item which is now designated from stockit' do
          package = create :package, :stockit_package, item: item
          stockit_item_params_with_designation[:stockit_id] = package.stockit_id
          stockit_item_params_with_designation[:quantity] = package.received_quantity
          expect{
            post :create, params: { package: stockit_item_params_with_designation }
          }.to change(OrdersPackage, :count).by(1)
          test_package_changes(package, response.status, order.code, location)
          stockit_request = GoodcitySync.request_from_stockit
          expect(package.reload.stockit_designated_by_id).to eq(stockit_user.id)
          test_orders_packages(package, stockit_request, 1)
        end

        it 'cancels designation and recreates one if Stockit re-designates' do
          package = create :package, :stockit_package, :with_inventory_record, item: item, received_quantity: 1
          order1 = create :order
          orders_package = create :orders_package, :with_state_designated, order: order1,
            package: package, quantity: 1
          stockit_item_params_with_designation[:stockit_id] = package.stockit_id
          expect{
            post :create, params: { package: stockit_item_params_with_designation }
          }.to change(OrdersPackage, :count).by(1)
          test_package_changes(package, response.status, order.code, location)
          stockit_request = GoodcitySync.request_from_stockit
          test_orders_packages(package, stockit_request, 2)
          expect(package.reload.stockit_designated_by_id).to eq(stockit_user.id)
          expect(package.orders_packages.first.order).to eq order1
          expect(package.orders_packages.first.state).to eq 'cancelled'
          expect(package.orders_packages.last.order).to eq order
          expect(package.orders_packages.last.state).to eq 'designated'
        end

        it 'cancels designation if item was previously designated and now its undesignated from stockit' do
          package = create :package, :stockit_package, :with_inventory_record, designation_name: 'abc', order: order, received_quantity: 1
          orders_package = create :orders_package, :with_state_designated, order: order,
            package: package, quantity: 1
          packages_location = create :packages_location, package: package, location: location,
            quantity: package.received_quantity
          stockit_item_params_without_designation[:stockit_id] = package.reload.stockit_id
          expect{
            post :create, params: { package: stockit_item_params_without_designation }
          }.to change(OrdersPackage, :count).by(0)
          test_package_changes(package, response.status, '', location)
          expect(package.reload.stockit_designated_by_id).to be_nil
          expect(package.reload.stockit_sent_by_id).to be_nil
          stockit_request = GoodcitySync.request_from_stockit
          test_orders_packages(package, stockit_request, 1)
          expect(orders_package.reload.state).to eq('cancelled')
        end

        it 'cancels existing orders_package and re-creates one if designated to some other order' do
          package = create :package, :stockit_package, designation_name: order1.code, received_quantity: 1
          initialize_inventory(package, location: location)
          orders_package = create :orders_package, :with_state_designated, order: order1, package: package, quantity: 1
          stockit_item_params_with_designation[:stockit_id] = package.reload.stockit_id
          expect{
            post :create, params: { package: stockit_item_params_with_designation }
          }.to change(OrdersPackage, :count).by(1)
          test_package_changes(package, response.status, order.code, location)
          stockit_request = GoodcitySync.request_from_stockit
          test_orders_packages(package, stockit_request, 2)
          expect(package.orders_packages.first.state).to eq('cancelled')
          expect(package.orders_packages.first.order).to eq(order1)
          expect(package.orders_packages.last.state).to eq('designated')
          expect(package.orders_packages.last.order).to eq(order)
        end
      end

      context 'Update quantity from Stockit' do
        let(:order) { create :order, :with_stockit_id }
        let(:package) { create :package, :with_inventory_record, :stockit_package, received_quantity: 1 }
        let!(:orders_package) { create :orders_package, :with_state_designated, order: order, package: package, quantity: 1 }

        let(:package_params){
          stockit_item_params.merge({
            quantity: 100,
            package_type_id:package.package_type_id,
            state: package.state,
            stockit_id: package.stockit_id,
            donor_condition_id: package.donor_condition_id,
            designation_name: order.code,
            order_id: order.stockit_id
          })
        }

        it 'update quantity of item with edit' do
          post :create, params: { package: package_params }
          expect(response.status).to eq(201)
          expect(PackagesInventory::Computer.package_quantity(package)).to eq(100)
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
        let(:order) { create :order, :with_stockit_id, :with_state_awaiting_dispatch }
        let(:package) {create :package, :with_inventory_record, :stockit_package, designation_name: order1.code, received_quantity: 10 }

        let(:stockit_params_with_designation){
          stockit_item_params.merge({
            stockit_designated_on: Date.today,
            designation_name: order.code,
            order_id: order.stockit_id
          })
        }

        let(:stockit_params_with_sent_on_and_designation){
          stockit_params_with_designation.merge({
            stockit_sent_on: Date.today
          })
        }

        it 'updates quantity of package, orders_package and packages_location record if item(designated) quantity is changed from stockit' do
          orders_package = create :orders_package, :with_state_designated, order: order,
            package: package, quantity: 10
          initialize_inventory(package)
          stockit_params_with_designation[:quantity] = 8
          stockit_params_with_designation[:stockit_id] = package.stockit_id
          expect{
            post :create, params: { package: stockit_params_with_designation }
          }.to change(OrdersPackage, :count).by(0)
          stockit_request = GoodcitySync.request_from_stockit
          expect(response.status).to eq(201)
          test_orders_packages(package, stockit_request, 1)
          expect(PackagesInventory::Computer.package_quantity(package)).to eq(8)
          expect(orders_package.reload.quantity).to eq(8)
          expect(package.packages_locations.first.quantity).to eq(8)
        end
      end

      context 'Dispatch & Undispatch from stockit' do
        let(:order) { create :order, :with_stockit_id, :with_state_dispatching }

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
          package = create :package, :with_inventory_record, :stockit_package, designation_name: 'abc', received_quantity: 1
          orders_package = create :orders_package, package: package, order: order,
            state: 'designated', quantity: 1
          stockit_params_with_sent_on_and_designation[:stockit_id] = package.stockit_id
           expect{
            post :create, params: { package: stockit_params_with_sent_on_and_designation }
          }.to change(OrdersPackage, :count).by(0)
          expect(response.status).to eq(201)
          test_package_changes(package, response.status, order.code, nil)
          expect(package.orders_packages.first.state).to eq 'dispatched'
          expect(package.packages_locations.size).to eq(0)
        end

        it 'creates new designation and then dispatch if package is not designated before dispatch from stockit' do
          package = create :package, :with_inventory_record, :stockit_package, designation_name: order.code, received_quantity: 1
          stockit_params_with_sent_on_and_designation[:stockit_id] = package.reload.stockit_id
          stockit_params_with_sent_on_and_designation[:quantity] = 1
          expect{
            post :create, params: { package: stockit_params_with_sent_on_and_designation }
          }.to change(OrdersPackage, :count).by(1)
          test_package_changes(package, response.status, order.code, nil)
          expect(package.orders_packages.first.state).to eq 'dispatched'
          expect(package.orders_packages.first.quantity).to eq 1
          expect(package.orders_packages.first.dispatched_quantity).to eq 1
          expect(PackagesInventory::Computer.package_quantity(package)).to eq 0
          expect(package.stockit_designated_by_id).to eq(stockit_user.id)
          expect(package.orders_packages.count).to eq 1
          expect(package.packages_locations.size).to eq(0)
        end

        it 'cancels existing designation and dispatches a new designation with new order_id it when dispatched from stockit with another order' do
          package = create :package, :with_inventory_record, :stockit_package, designation_name: order_1.code, received_quantity: 5
          orders_package = create :orders_package, package: package, order: order_1, state: 'designated'
          stockit_params_with_sent_on_and_designation[:stockit_id] = package.stockit_id
          expect{
            post :create, params: { package: stockit_params_with_sent_on_and_designation }
          }.to change(OrdersPackage, :count).by(1)
          test_package_changes(package, response.status, order.code, nil)

          expect(orders_package.reload.state).to eq 'cancelled'

          new_orders_package = package.reload.orders_packages.last
          expect(new_orders_package.state).to eq 'dispatched'
          expect(package.packages_locations.size).to eq(0)
        end

        it 'dispatches existing designation if available with same order_id' do
          package = create :package, :with_inventory_record, :stockit_package, received_quantity: 10
          orders_package = create :orders_package, :with_state_designated, package: package, order: order, quantity: 1
          stockit_params_with_sent_on_and_designation[:stockit_id] = package.reload.stockit_id
          stockit_params_with_sent_on_and_designation[:quantity]   = 1
          expect{
            post :create, params: { package: stockit_params_with_sent_on_and_designation }
          }.to change(OrdersPackage, :count).by(0)
          test_package_changes(package, response.status, order.code, nil)
          expect(orders_package.reload.state).to eq 'dispatched'
        end

        it 'undispatches orders_package with matching order_id when Undispatch request from stockit.' do
          package = create :package, :with_inventory_record, :stockit_package, stockit_sent_on: Date.today,
            order_id: order.id, received_quantity: 1, stockit_designated_by: stockit_user
          orders_package = create :orders_package, :with_inventory_record, package: package,
            order: order, state: 'dispatched', sent_on: Date.today, quantity: 1
          stockit_params_without_sent_on[:stockit_id] = package.reload.stockit_id
          stockit_params_without_sent_on[:location_id] = dispatched_location.stockit_id
          expect{
            post :create, params: { package: stockit_params_without_sent_on }
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

  describe "PUT package/1/split_package" do
    let(:package) { create :package, :with_inventory_record, received_quantity: 5 }

    before do
      allow(Stockit::ItemSync).to receive(:create)
      allow(Stockit::ItemSync).to receive(:update)
      generate_and_set_token(user)
      touch(package)
    end

    it "creates a new package with the split quantity" do
      expect {
        put :split_package, params: { id: package.id, package: { quantity: 2 } }
      }.to change(Package, :count).from(1).to(2)

      expect(response.status).to eq(200)

      new_package = Package.last
      expect(PackagesInventory::Computer.package_quantity(new_package)).to eq(2)
      expect(new_package.inventory_number).to eq(package.inventory_number + "Q1")
    end

    it "reduces the quantity of the original package" do
      expect {
        put :split_package, params: { id: package.id, package: { quantity: 2 } }
      }.to change {
        PackagesInventory::Computer.package_quantity(package)
      }.from(5).to(3)
    end

    it "fails if the value is invalid" do
      expect {
        put :split_package, params: { id: package.id, package: { quantity: 10 } }
      }.not_to change(Package, :count)

      expect(response.status).to eq(422)
      expect(parsed_body['error']).to eq("Quantity to split should be at least 1 and less than 5")
    end
  end

  with_versioning do
    describe "GET package/1/versions" do
      let(:electrical) { create :electrical }
      let(:package) { create :package, detail: electrical }

      before do
        generate_and_set_token(user)
        allow(Stockit::ItemDetailSync).to receive(:create).and_return({ 'success' => 201 })
      end

      it "returns 200" do
        get :versions, params: { id: package.id }
        expect(response.status).to eq(200)
      end

      it "returns versions of packages" do
        # FAIL
        get :versions, params: { id: package.id }
        expect(parsed_body['versions'].size).to eq(package.versions.size + electrical.versions.size)
        expect(parsed_body["versions"].first["id"]).to eq(package.versions.first.id)
      end

      it "returns versions of detail along with package versions" do
        # FAIL
        get :versions, params: { id: package.id }
        expect(parsed_body["versions"].map { |version| version["id"] }).to include(electrical.versions.first.id)
      end
    end
  end

  describe "PUT package/1" do
    let(:location) { create :location }
    let(:uninventorized_package) { create :package }
    let(:updated_package_id) { parsed_body['package']['id'] }
    let(:updated_package) { Package.find(updated_package_id) }

    before { generate_and_set_token(user) }

    it "reviewer can update", :show_in_doc do
      updated_params = { quantity: 30, width: 100 }
      put :update, params: { id: package.id, package: package_params.merge(updated_params) }
      expect(response.status).to eq(200)
    end

    it "add stockit item-update request" do
      package = create :package, :received
      updated_params = { quantity: 30, width: 100, state: "received" }
      # expect(StockitUpdateJob).to receive(:perform_later).with(package.id)
      put :update, params: { id: package.id, package: package_params.merge(updated_params) }
    end

    context "by setting an inventory_number for the first time" do
      before { package_params[:inventory_number] = '98767' }

      context "and a location_id" do
        before { package_params[:location_id] = location.id }

        it "created a packages_inventory 'inventory' action row" do
          expect(uninventorized_package.inventory_number).to be_nil

          expect {
            put :update, params: { id: uninventorized_package.id, package: package_params }
          }.to change(PackagesInventory, :count).from(0).to(1)

          expect(response.status).to eq(200)
          expect(PackagesInventory.last.package_id).to eq(updated_package_id)
          expect(PackagesInventory.last.quantity).to eq(updated_package.received_quantity)
          expect(PackagesInventory.last.location_id).to eq(location.id)
          expect(PackagesInventory.last.action).to eq('inventory')
        end

        it "creates the packages_locations relation (through packages_inventory sync)" do
          put :update, params: { id: uninventorized_package.id, package: package_params }
          expect(response.status).to eq(200)
          expect(updated_package.packages_locations.count).to eq(1)
          expect(updated_package.packages_locations.first.location_id).to eq(location.id)
          expect(updated_package.packages_locations.first.quantity).to eq(uninventorized_package.received_quantity)
        end
      end

      context "but without a location_id" do
        it "does not create any packages_location" do
          put :update, params: { id: uninventorized_package.id, package: package_params }
          expect(response.status).to eq(200)
          expect(updated_package.packages_locations.count).to eq(0)
        end

        it "does not create any packages_inventory record" do
          put :update, params: { id: uninventorized_package.id, package: package_params }
          expect(response.status).to eq(200)
          expect(PackagesInventory.count).to eq(0)
        end
      end
    end

    context "without setting an inventory_number" do
      context "but with a location" do
        before { package_params[:location_id] = location.id }

        it "does not create any packages_location (location is ignored)" do
          put :update, params: { id: uninventorized_package.id, package: package_params }
          expect(response.status).to eq(200)
          expect(updated_package.packages_locations.count).to eq(0)
        end

        it "does not create any packages_inventory record (location is ignored)" do
          put :update, params: { id: uninventorized_package.id, package: package_params }
          expect(response.status).to eq(200)
          expect(PackagesInventory.count).to eq(0)
        end
      end
    end

    context "setting a location" do
      context "to a package which already has an inventory number" do
        before do
          uninventorized_package.update(inventory_number: '9847')
          package_params[:location_id] = location.id
        end

        it "created a packages_inventory 'inventory' action row" do
          expect(uninventorized_package.inventory_number).not_to be_nil

          expect {
            put :update, params: { id: uninventorized_package.id, package: package_params }
          }.to change(PackagesInventory, :count).from(0).to(1)

          expect(response.status).to eq(200)
          expect(PackagesInventory.last.package_id).to eq(updated_package_id)
          expect(PackagesInventory.last.quantity).to eq(updated_package.received_quantity)
          expect(PackagesInventory.last.location_id).to eq(location.id)
          expect(PackagesInventory.last.action).to eq('inventory')
        end

        it "creates the packages_locations relation (through packages_inventory sync)" do
          put :update, params: { id: uninventorized_package.id, package: package_params }
          expect(response.status).to eq(200)
          expect(updated_package.packages_locations.count).to eq(1)
          expect(updated_package.packages_locations.first.location_id).to eq(location.id)
          expect(updated_package.packages_locations.first.quantity).to eq(package.received_quantity)
        end
      end
    end
  end

  describe "DELETE package/1" do
    let(:uninventorized_package) { create :package, inventory_number: nil }

    before { generate_and_set_token(user) }

    it "deletes an uninventorized package successfully", :show_in_doc do
      expect(PackagesInventory.where(package: uninventorized_package).count).to eq(0)

      delete :destroy, params: { id: uninventorized_package.id }
      expect(response.status).to eq(200)
      expect(subject).to eq( {} )
    end

    it "fails to deletes an inventorized package successfully", :show_in_doc do
      expect(PackagesInventory.where(package: package).count).to be > 0
      delete :destroy, params: { id: package.id }
      expect(response.status).to eq(422)
      expect(subject['error']).to eq("Inventorized packages cannot be deleted")
    end
  end

  describe "POST print_barcode" do
    before { generate_and_set_token(user) }
    let(:inventory_number) {"000055"}
    let(:package) { create :package }
    let!(:printer_1) { create :printer, :active }
    let!(:printer_2) { create :printer }


    it "returns 400 if package does not exist" do
      post :print_barcode, params: { package_id: 1, labels:1 }
      expect(response.status).to eq(400)
      expect(subject["errors"]).to eq("Package not found with supplied package_id")
    end

    it "should generate inventory number if empty on package" do
      expect(package.inventory_number).to be_blank
      post :print_barcode, params: { package_id: package.id, labels:1 }
      package.reload
      expect(package.inventory_number).not_to be_blank
    end

    it "should print barcode service call with inventory number" do
      package.inventory_number = inventory_number
      package.save
      expect(PrintLabelJob).to receive(:perform_later).with(package.id, user.id, {label: 'inventory_label', print_count:1, tag: 'stock' })

      post :print_barcode, params: { package_id: package.id, labels: 1, tag: 'stock' }
    end

    it "return 204 status" do
      post :print_barcode, params: { package_id: package.id, labels:1 }
      expect(response.status).to eq(204)
    end

    it "returns 400 if labels quantity is more than 300" do
      post :print_barcode, params: { package_id: package.id, labels:301 }
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
      get :search_stockit_items, params: { searchText: "456" }
      expect(response.status).to eq(200)
      expect(subject['meta']['search']).to eql("456")
      expect(subject['items'].map{|i| i['inventory_number']}).to match_array(['456222', '456111', '456333'])
    end

    it 'should find items by inventory number (includes quantity items)' do
      create :package, received_quantity: 1, inventory_number: "456333"
      create :package, received_quantity: 2, inventory_number: "456222"
      create :package, received_quantity: 2, inventory_number: "456111"
      get :search_stockit_items, params: { searchText: "456", showQuantityItems: 'true' }
      expect(response.status).to eq(200)
      expect(subject['meta']['search']).to eql("456")
      expect(subject['items'].map{|i| i['inventory_number']}).to match_array(['456222', '456111', '456333'])
    end

    it 'should find items by notes' do
      create :package, received_quantity: 1, notes: "butter", inventory_number: "456333"
      create :package, received_quantity: 1, notes: "butterfly", inventory_number: "456222"
      create :package, received_quantity: 1, notes: "margarine", inventory_number: "456111"
      get :search_stockit_items, params: { searchText: "UTter", showQuantityItems: 'true' }
      expect(response.status).to eq(200)
      expect(subject['meta']['search']).to eql("UTter")
      expect(subject['items'].map{|i| i['notes']}).to match_array(['butter', 'butterfly'])
    end

    it 'should find items by case number' do
      create :package, received_quantity: 1, case_number: "CAS-123", inventory_number: "456333"
      create :package, received_quantity: 1, case_number: "CAS-124", inventory_number: "456222"
      create :package, received_quantity: 1, case_number: "CAS-666", inventory_number: "456111"
      get :search_stockit_items, params: { searchText: "cas-12", showQuantityItems: 'true' }
      expect(response.status).to eq(200)
      expect(subject['meta']['search']).to eql("cas-12")
      expect(subject['items'].map{|i| i['case_number']}).to match_array(['CAS-123', 'CAS-124'])
    end

    it 'should find items by designation_name' do
      create :package, received_quantity: 1, designation_name: "pepper", inventory_number: "456333"
      create :package, received_quantity: 1, designation_name: "peppermint", inventory_number: "456222"
      create :package, received_quantity: 1, designation_name: "garlic", inventory_number: "456111"
      get :search_stockit_items, params: { searchText: "peP", showQuantityItems: 'true' }
      expect(response.status).to eq(200)
      expect(subject['meta']['search']).to eql("peP")
      expect(subject['items'].map{|i| i['designation_name']}).to match_array(['pepper', 'peppermint'])
    end

    it 'should use filters to only find items that have an inventory number and are marked as received' do
      create :package, received_quantity: 1, designation_name: "couch", inventory_number: '11111', state: 'received'
      create :package, received_quantity: 1, designation_name: "couch", inventory_number: '22222', state: 'missing'
      create :package, received_quantity: 1, designation_name: "couch", inventory_number: nil, state: 'received'
      create :package, received_quantity: 1, designation_name: "couch", inventory_number: nil, state: 'missing'
      get :search_stockit_items, params: { searchText: 'couch', showQuantityItems: 'true', state: 'received' }
      expect(response.status).to eq(200)
      expect(subject['meta']['search']).to eql('couch')
      expect(subject['items'].map{|i| i['inventory_number']}).to match_array(['11111'])
    end

    it 'should filter out item with published, has_images, and in_stock status' do
      initialize_inventory(
        create(:package, inventory_number: "111000", state: 'received', received_quantity: 1),
        create(:package, inventory_number: "111001", state: 'received', allow_web_publish: true, received_quantity: 1),
        create(:package, :with_images, inventory_number: "111005", allow_web_publish: true, state: 'received', received_quantity: 1)
      )
      params = {
        searchText: '111',
        showQuantityItems: 'true',
        withInventoryNumber: 'true',
        state:'in_stock,published,has_images'
      }
      get :search_stockit_items, params: params
      expect(response.status).to eq(200)
      expect(subject['meta']['search']).to eql('111')
      expect(subject['items'].map{|i| i['inventory_number']}).to match_array(['111005'])

    end

    it "filter out multiquantity items if params has restrictMultiQuantity field" do
      initialize_inventory(
        create(:package, inventory_number: "111000", received_quantity: 1),
        create(:package, inventory_number: "111001", received_quantity: 8),
        create(:package, inventory_number: "111005", received_quantity: 1)
      )
      params = {
        searchText: '111',
        stockRequest: true,
        restrictMultiQuantity: 'true',
        withInventoryNumber: 'true'
      }
      get :search_stockit_items, params: params
      expect(response.status).to eq(200)
      expect(subject["items"].count).to eq(2)
    end

    it "find multiquantity items if params does not have restrictMultiQuantity field" do
      initialize_inventory(
        create(:package, inventory_number: "111000", received_quantity: 1),
        create(:package, inventory_number: "111001", received_quantity: 8),
        create(:package, inventory_number: "111005", received_quantity: 1)
      )
      params = {
        searchText: '111',
        stockRequest: true,
        withInventoryNumber: 'true'

      }
      get :search_stockit_items, params: params
      expect(response.status).to eq(200)
      expect(subject["items"].count).to eq(3)
    end

    it "search single quantity item created after Splitting of package" do
      initialize_inventory(
        create(:package, inventory_number: "F00001Q1", received_quantity: 2),
        create(:package, inventory_number: "F00001Q2", received_quantity: 2),
        create(:package, inventory_number: "F00001Q3", received_quantity: 1)
      )
      params = {
        searchText: 'F00001Q',
        stockRequest: true,
        restrictMultiQuantity: 'true',
        withInventoryNumber: 'true'
      }
      get :search_stockit_items, params: params
      expect(response.status).to eq(200)
      expect(subject["items"].count).to eq(1)
    end

    it "response should have total_pages, and search in meta data" do
      initialize_inventory(
        create(:package, inventory_number: "F00001Q1", received_quantity: 2),
        create(:package, inventory_number: "F00001Q2", received_quantity: 2),
        create(:package, inventory_number: "F00001Q3", received_quantity: 1)
      )
      searchText = 'F00001Q'
      params = {
        searchText: searchText,
        stockRequest: true,
        restrictMultiQuantity: 'true',
        withInventoryNumber: 'true',
        page:1,
        per_page:25
      }
      get :search_stockit_items, params: params
      expect(subject["meta"]["search"]).to eq(searchText)
      expect(subject["meta"].keys).to include("total_pages")
    end
  end

  context "box/pallet" do
    let(:user) { create(:user, :supervisor, :with_can_manage_packages_permission) }
    let(:box_storage) { create(:storage_type, :with_box) }
    let(:pallet_storage) { create(:storage_type, :with_pallet) }
    let(:package_storage) { create(:storage_type, :with_pkg) }
    let(:box) { create(:package, :with_inventory_record, storage_type: box_storage) }
    let(:pallet) { create(:package, :with_inventory_record, storage_type: pallet_storage) }
    let(:package1) { create(:package, :with_inventory_number, received_quantity: 50, storage_type: package_storage)}
    let(:package2) { create(:package, :with_inventory_number, received_quantity: 40, storage_type: package_storage)}
    let(:box_package) { create(:package, :with_inventory_number, received_quantity: 1, storage_type: box_storage) }
    let(:location) { Location.create(building: "21", area: "D") }
    let!(:creation_setting) { create(:goodcity_setting, key: "stock.enable_box_pallet_creation", value: "true") }
    let!(:addition_setting) { create(:goodcity_setting, key: "stock.allow_box_pallet_item_addition", value: "true") }

    before {
      initialize_inventory(package1, package2, box_package, location: location)
    }

    def pack(qty, pkg, into:)
      Package::Operations.pack_or_unpack(container: into, package: pkg, location_id: location.id, quantity: qty, user_id: user.id, task: 'pack')
    end

    def unpack(qty, pkg, out_of:)
      Package::Operations.pack_or_unpack(container: out_of, package: pkg, location_id: location.id, quantity: qty, user_id: user.id, task: 'unpack')
    end

    describe "Get containers of a package (/package/:id/parent_containers)" do
      let(:response_packages) { parsed_body['items'].map { |it| Package.find(it['id']) } }

      before { generate_and_set_token(user) }

      before(:each) do
        pack(20, package1, into: box)
        pack(10, package1, into: pallet)

        expect(PackagesInventory::Computer.package_quantity(package1)).to eq(20)
        expect(PackagesInventory::Computer.package_quantity(box)).to eq(1)
        expect(PackagesInventory::Computer.package_quantity(pallet)).to eq(1)
      end

      it "fetches all the boxes/pallets that contain the package" do
        get :parent_containers, params: { id: package1.id }
        expect(response.status).to eq(200)
        expect(response_packages).to match_array([box, pallet]);
      end

      it "does not return a box if the package has been taken out of it" do
        unpack(20, package1, out_of: box)

        get :parent_containers, params: { id: package1.id }
        expect(response.status).to eq(200)
        expect(response_packages).to match_array([pallet]);
      end
    end

    describe "fetch contained_packages" do
      before :each do
        generate_and_set_token(user)
        current_user = user
        pack(5, package1, into: box)
        pack(2, package2, into: box)
        pack(5, package2, into: pallet)
      end

      it "fetches all the items that are present inside a box" do
        get :contained_packages, params: { id: box.id }
        expect(response.status).to eq(200)
        expect(parsed_body["items"].length).to eq(2)
      end

      it "fetches all the items that are present inside a pallet" do
        get :contained_packages, params: { id: pallet }
        expect(response.status).to eq(200)
        expect(parsed_body["items"].length).to eq(1)
      end
    end

    describe "add_remove_item" do
      let(:params) { { id: box.id, item_id: package1.id, location_id: location.id, task: 'pack', quantity: 5 } }

      before(:each) do
        generate_and_set_token(user)
        current_user = user
      end

      context 'add item to container' do
        it "adds an item to the box" do
          put :add_remove_item, params: params
          expect(response.status).to eq(201)
          expect([parsed_body["packages_inventories"]].length).to eq(1)
          expect(parsed_body["packages_inventories"]["package_id"]).to eq(package1.id)
          expect(parsed_body["packages_inventories"]["source_id"]).to eq(box.id)
          expect(parsed_body["packages_inventories"]["source_type"]).to eq("Package")
          expect(parsed_body["packages_inventories"]["action"]).to eq("pack")
          expect(parsed_body["packages_inventories"]["quantity"]).to eq(-5)
        end

        context 'when item is added to box' do
          it 'updates the on_hand_boxed_quantity' do
            put :add_remove_item, params: params
            expect(package1.reload.on_hand_boxed_quantity).to eq(5)
          end

          it 'does not change the the on_hand_palletized_quantity' do
            put :add_remove_item, params: params
            expect(package1.reload.on_hand_palletized_quantity).to eq(0)
          end
        end

        context 'when item is added to pallet' do
          let(:params) { {  id: pallet.id, item_id: package1.id, location_id: location.id, task: 'pack', quantity: 3} }

          it 'updates the on_hand_palletized_quantity' do
            put :add_remove_item, params: params
            expect(package1.reload.on_hand_palletized_quantity).to eq(3)
          end

          it 'does not change the the on_hand_boxed_quantity' do
            put :add_remove_item, params: params
            expect(package1.reload.on_hand_boxed_quantity).to eq(0)
          end
        end

        context 'when box is added to the pallet' do
          let(:params) { { id: pallet.id, item_id: box_package.id, location_id: location.id, task: 'pack', quantity: 1 } }

          it 'updates the on_hand_palletized_quantity' do
            put :add_remove_item, params: params
            expect(box_package.reload.on_hand_palletized_quantity).to eq(1)
          end

          it 'does not change the on_hand_boxed_quantity' do
            put :add_remove_item, params: params
            expect(box_package.on_hand_boxed_quantity).to eq(0)
          end
        end

        context 'item is added to both box and pallet' do
          before do
            Package::Operations.pack_or_unpack(container: pallet, package: package1, quantity: 3, location_id: location.id, user_id: user.id, task: 'pack')
          end

          it 'updates on_hand_palletized_quantity and on_hand_boxed_quantity' do
            put :add_remove_item, params: params
            expect(package1.reload.on_hand_palletized_quantity).to eq(3)
            expect(package1.on_hand_boxed_quantity).to eq(5)
          end
        end
      end

      context 'remove item from container' do
        let(:box_unpack_params) { { id: box.id, item_id: package1.id, location_id: location.id, task: 'unpack', quantity: 3 } }
        let(:pallet_pack_params) { { id: pallet.id, item_id: package1.id, location_id: location.id, task: 'pack', quantity: 3 } }


        it "removes an item from the box" do
          put :add_remove_item, params: params # add to box
          put :add_remove_item, params: box_unpack_params # remove it
          expect(response.status).to eq(201)
          expect([parsed_body["packages_inventories"]].length).to eq(1)
          expect(parsed_body["packages_inventories"]["package_id"]).to eq(package1.id)
          expect(parsed_body["packages_inventories"]["source_id"]).to eq(box.id)
          expect(parsed_body["packages_inventories"]["source_type"]).to eq("Package")
          expect(parsed_body["packages_inventories"]["action"]).to eq("unpack")
          expect(parsed_body["packages_inventories"]["quantity"]).to eq(3)
        end

        context 'when item is removed from box' do
          it 'updates the on_hand_boxed_quantity' do
            put :add_remove_item, params: params # add to box
            put :add_remove_item, params: box_unpack_params # remove it
            expect(package1.reload.on_hand_boxed_quantity).to eq(2)
          end
        end

        context 'when item is removed from pallet' do
          it 'updates the on_hand_palletized_quantity' do
            put :add_remove_item, params: pallet_pack_params # add to pallet
            pallet_pack_params[:task] = 'unpack'
            pallet_pack_params[:quantity] = 2
            put :add_remove_item, params: pallet_pack_params # remove it
            expect(package1.reload.on_hand_palletized_quantity).to eq(1)
          end
        end

        context 'when item has both on_hand box and pallet quantity' do
          before do
            Package::Operations.pack_or_unpack(container: pallet, package: package1, quantity: 3, location_id: location.id, user_id: user.id, task: 'pack')

            Package::Operations.pack_or_unpack(container: box, package: package1, quantity: 5, location_id: location.id, user_id: user.id, task: 'pack')
          end

          context 'on removing few items from box' do
            before do
              params[:task] = 'unpack'
              params[:quantity] = 2
              put :add_remove_item, params: params
            end

            it 'updates the on_hand_boxed_quantity' do
              expect(package1.reload.on_hand_boxed_quantity).to eq(3)
            end

            it 'does not change on_hand_palletized_quantity' do
              expect(package1.reload.on_hand_palletized_quantity).to eq(3)
            end
          end

          context 'on removing few items from pallet' do
            before do
              pallet_pack_params[:task] = 'unpack'
              pallet_pack_params[:quantity] = 2
              put :add_remove_item, params: pallet_pack_params
            end

            it 'updates the on_hand_palletized_quantity' do
              expect(package1.reload.on_hand_palletized_quantity).to eq(1)
            end

            it 'does not change the on_hand_boxed_quantity' do
              expect(package1.reload.on_hand_boxed_quantity).to eq(5)
            end
          end

          context 'on removing all items from box' do
            before do
              params[:task] = 'unpack'
              params[:quantity] = 5
              put :add_remove_item, params: params
            end

            it 'on_hand_box_quantity will be 0' do
              expect(package1.reload.on_hand_boxed_quantity).to eq(0)
            end

            it 'does not change the on_hand_palletized_quantity' do
              expect(package1.reload.on_hand_palletized_quantity).to eq(3)
            end
          end

          context 'on removing all items from pallet' do
            before do
              pallet_pack_params[:task] = 'unpack'
              pallet_pack_params[:quantity] = 3
              put :add_remove_item, params: pallet_pack_params
            end

            it 'on_hand_palletized_quantity will be 0' do
              expect(package1.reload.on_hand_palletized_quantity).to eq(0)
            end

            it 'does not change the on_hand_box_quantity' do
              expect(package1.reload.on_hand_boxed_quantity).to eq(5)
            end
          end
        end
      end

      context 'if selected quantity is 0' do
        let(:params) { { id: box.id, item_id: package1.id, location_id: location.id, task: 'pack', quantity: 0 } }

        it "doesnot create packages inventory record if selected quantity is 0" do
          put :add_remove_item, params: params
          expect(response.status).to eq(204)
        end

        it 'does not change the on_hand_xxx_quantity' do
          put :add_remove_item, params: params
          expect(package1.reload.on_hand_boxed_quantity).to eq(0)
          expect(package1.reload.on_hand_palletized_quantity).to eq(0)
        end
      end

      it "throws adding box to a box error" do
        put :add_remove_item, params: { id: box.id, item_id: box.id, location_id: box.location_id, task: 'pack', quantity: 5 }
        expect(response.status).to eq(422)
        expect(parsed_body["errors"]).to eq(["Cannot add a box to another box."])
      end

      it "throws quantity error" do
        put :add_remove_item, params: { id: box.id, item_id: package2.id, location_id: location.id, task: "pack", quantity: package2.on_hand_quantity + 20 }
        expect(response.status).to eq(422)
        expect(parsed_body["errors"]).to eq(["The selected quantity (60) is unavailable"])
      end

      context 'when already designated' do
        let(:params) { { id: box.id, item_id: package2.id, location_id: location.id, task: 'pack', quantity: 2 } }

        before(:each) do
          GoodcitySync.request_from_stockit = true
          Package::Operations.designate(package2, quantity: package2.available_quantity, to_order: create(:order, state: "submitted").id)
        end

        it "throws already designated error" do
          put :add_remove_item, params: params
          expect(response.status).to eq(422)
          expect(parsed_body["errors"]).to eq(["Cannot add/remove designated/dispatched items."])
        end

        it 'does not change the on_hand_xxx_quantity' do
          put :add_remove_item, params: params
          expect(package2.reload.on_hand_boxed_quantity).to eq(0)
          expect(package2.reload.on_hand_palletized_quantity).to eq(0)
        end
      end
    end
  end

  describe 'PUT register_quantity_change' do
    before do
      generate_and_set_token(user)
      @package = create :package
      @location = create :location
      @package = create(:package, :with_inventory_number, received_quantity: 20)
      create(:packages_location, package: @package, location: @location, quantity: 20)
    end

    it 'performs loss action on package' do
      expect(@package.packages_locations.first.quantity).to eq(20)

      put :register_quantity_change, {
                          params: {
                            id: @package.id,
                            quantity: 2,
                            from: @location.id,
                            action_name: "loss",
                            description: "Loss action on Package",
                          }
                        }

      expect(response.status).to eq(200)
      expect(@package.packages_locations.first.quantity).to eq(18)
      expect(@package.package_actions.last.action).to eq('loss')
      expect(@package.package_actions.last.quantity).to eq(-2)
    end

    it "performs gain action on package" do
      expect(@package.packages_locations.first.quantity).to eq(20)

      put :register_quantity_change, {
            params: {
              id: @package.id,
              quantity: 10,
              from: @location.id,
              action_name: "gain",
              description: "gain action on Package",
            }
          }

      expect(response.status).to eq(200)
      expect(@package.packages_locations.first.quantity).to eq(30)
      expect(@package.package_actions.last.action).to eq("gain")
      expect(@package.package_actions.last.quantity).to eq(10)
    end

    it "throws error for unsupported action" do
      put :register_quantity_change, {
                          params: {
                            id: @package.id,
                            quantity: 2,
                            from: @location.id,
                            action_name: "invalid_action",
                            description: "Unsupported action on Package",
                          }
                        }

      expect(response.status).to eq(422)
      expect(parsed_body["error"]).to eq("Action you are trying to perform is not allowed")
    end

    it "throws error for invalid quantity" do
      put :register_quantity_change, {
                          params: {
                            id: @package.id,
                            quantity: 25,
                            from: @location.id,
                            action_name: "loss",
                            description: "Loss action on Package",
                          }
                        }

      expect(response.status).to eq(422)
      expect(parsed_body['error']).to eq("The selected quantity (25) is unavailable")
    end
  end

  describe 'GET stockit_items' do
    before do
      generate_and_set_token(user)
      @location = create :location
      @package = create(:package, :with_inventory_number, received_quantity: 20)
      create(:packages_location, package: @package, location: @location, quantity: 20)
    end

    it 'returns package details' do
      get :stockit_item_details, params: { id: @package.id }
      expect(response).to have_http_status(:success)
    end

    it 'should have saleable node in the response' do
      get :stockit_item_details, params: {id: @package.id}
      expect(parsed_body['item'].keys).to include('saleable')
    end
  end

  describe 'GET package_valuation' do
    let!(:donor_condition) { create :donor_condition }
    let!(:package_type) { create :package_type }
    let!(:valuation_matrix) { create :valuation_matrix, donor_condition_id: donor_condition.id, grade: 'A' }

    before do
      generate_and_set_token(supervisor)
    end

    it 'returns valuation for the package' do
      package = Package.new(package_type_id: package_type.id, donor_condition_id: donor_condition.id, grade: 'A')
      get :package_valuation, params: { package_type_id: package_type.id,  donor_condition_id: donor_condition.id, grade: package.grade }
      expect(response).to have_http_status(:success)
      expect(parsed_body['value_hk_dollar']).to eq(package.calculate_valuation)
    end
  end
end
