require "rails_helper"

RSpec.describe Api::V1::PackagesController, type: :controller do

  let(:user) { create(:user_with_token, :reviewer) }
  let(:donor) { create(:user_with_token) }
  let(:offer) { create :offer, created_by: donor }
  let(:item)  { create :item, offer: offer }
  let(:package_type)  { create :package_type }
  let(:package) { create :package, item: item }
  let(:serialized_package) { Api::V1::PackageSerializer.new(package) }
  let(:serialized_package_json) { JSON.parse( serialized_package.to_json ) }

  let(:package_params) do
    FactoryGirl.attributes_for(:package, item_id: "#{item.id}", package_type_id: "#{package_type.id}")
  end

  subject { JSON.parse(response.body) }

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

  describe "POST package/1" do
   before { generate_and_set_token(user) }
    it "reviewer can create", :show_in_doc do
      post :create, format: :json, package: package_params
      expect(response.status).to eq(201)
      expect(GoodcitySync.request_from_stockit).to eq(false)
    end

    context "Received from Stockit" do
      let(:package) { create :package, :stockit_package, item: item }
      let(:location) { create :location }
      let(:stockit_item_params) {
        { designation_name: "HK",
          quantity: 1,
          inventory_number: package.inventory_number,
          location_id: location.stockit_id,
          donor_condition: item.donor_condition.name,
          grade: "C",
          stockit_id: package.stockit_id }
      }

      it "update designation_name, location, donor_condition, grade", :show_in_doc do
        post :create, format: :json, package: stockit_item_params
        expect(package.reload.designation_name).to eq("HK")
        expect(package.reload.location).to eq(location)
        expect(package.donor_condition).to eq(item.donor_condition)
        expect(package.grade).to eq("C")
        expect(response.status).to eq(201)
        expect(GoodcitySync.request_from_stockit).to eq(true)
      end

      # it "should not create new package for unknown inventory_number" do
      #   expect {
      #     post :create, format: :json, package: { designation_name: "HK", inventory_number: "F12345" }
      #   }.to_not change(Package, :count)
      #   expect(response.status).to eq(204)
      # end
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
