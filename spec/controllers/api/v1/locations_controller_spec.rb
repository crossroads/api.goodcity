require 'rails_helper'

RSpec.describe Api::V1::LocationsController, type: :controller do
  let(:reviewer) { create(:user, :with_token, :with_can_manage_locations_permission, role_name: 'Reviewer') }
  let(:parsed_body) { JSON.parse(response.body) }
  before { generate_and_set_token(reviewer) }

  describe "GET locations" do
    let(:locations) { create_list(:location, 2) }

    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized locations", :show_in_doc do
      create_list(:location, 2)
      get :index
      expect( parsed_body['locations'].length ).to eq(Location.count)
    end

    it "finds location using searchText" do
      create :location, building: "TestBuilding"
      create :location
      get :index, params: { searchText: "TestBuilding" }
      expect(parsed_body['locations'][0]['building']).to eql("TestBuilding")
      expect(parsed_body['meta']['total_pages']).to eql(1)
    end
  end

  describe "POST location/1" do
    it "create new location", :show_in_doc do
      expect {
        post :create, params: { location: {building: "234", area: "C" } }
      }.to change(Location, :count).by(1)
      expect(response.status).to eq(201)
    end
  end

  describe "PUT locations/:id" do
    let!(:location) { create(:location, building: "F1", area: "A") }

    it "renames the location", :show_in_doc do
      expect {
        put :update, params: { id: location.id, format: :json, location: { building: "F2", area: "B" } }
      }.to change { location.reload.building }.from("F1").to("F2")
      expect(response.status).to eq(200)
      expect(location.area).to eq("B")
      expect(parsed_body["location"]["area"]).to eq("B")
    end

    it "ignores unpermitted attributes" do
      put :update, params: { id: location.id, format: :json, location: { building: "F2", id: 999_999 } }
      expect(response.status).to eq(200)
      expect(location.reload.id).not_to eq(999_999)
    end

    context "as a user who cannot manage locations" do
      let(:normal_user) { create(:user, :with_token, role_name: 'Reviewer') }
      before { generate_and_set_token(normal_user) }

      it "returns 403 and does not change the record" do
        put :update, params: { id: location.id, format: :json, location: { building: "X" } }
        expect(response.status).to eq(403)
        expect(location.reload.building).to eq("F1")
      end
    end
  end

  # The stock-count / printer attributes are the Locations admin screen's own, delivered by LocationAdminSerializer
  # ONLY when the explicit with_counts param is sent. The shared LocationSerializer (nested in ~9 other serializers
  # and read by the legacy stock app's GET /locations) must stay { id, building, area }.
  describe "stock and printer fields (with_counts)" do
    let!(:location) { create(:location, building: "G1", area: "Z") }

    it "includes packages_count (distinct packages) and printer_name when with_counts is sent" do
      package = create(:package)
      create(:packages_location, location: location, package: package, quantity: 1)
      create(:packages_location, location: location, package: create(:package), quantity: 1)
      create(:printer, location: location, name: "Dock Printer")
      get :index, params: { with_counts: true }
      row = parsed_body["locations"].find { |l| l["id"] == location.id }
      expect(row["packages_count"]).to eq(2)
      expect(row["printer_name"]).to eq("Dock Printer")
      expect(row["building"]).to eq("G1")
    end

    it "returns 0 and nil when the location is empty and has no printer" do
      get :index, params: { with_counts: true }
      row = parsed_body["locations"].find { |l| l["id"] == location.id }
      expect(row["packages_count"]).to eq(0)
      expect(row["printer_name"]).to be_nil
    end

    it "does NOT add the admin attributes to the shared serializer (no with_counts)" do
      create(:printer, location: location, name: "Dock Printer")
      get :index
      row = parsed_body["locations"].find { |l| l["id"] == location.id }
      expect(row).not_to have_key("packages_count")
      expect(row).not_to have_key("printer_name")
      expect(row.keys).to match_array(%w[id building area])
    end

    # (The ?ids= path cannot be exercised over HTTP: apipie's `param :ids, Array, of: Integer` rejects the
    # string values a query string carries with a 422, so the other non-cached read path is searchText.)
    it "does NOT add the admin attributes to the searchText path without with_counts" do
      get :index, params: { searchText: "G1" }
      row = parsed_body["locations"].find { |l| l["id"] == location.id }
      expect(row).not_to have_key("packages_count")
      expect(row).not_to have_key("printer_name")
    end
  end

  # API-39: the plain GET /locations is the CacheableJson body. Deleting a location that was not the most
  # recently updated left MAX(updated_at) unchanged, so the deleted row stayed in that cached list.
  describe "DELETE locations/:id then the cached GET locations" do
    before { Rails.cache.clear }

    it "omits the deleted location from the plain (cached) index" do
      first = create(:location, building: "DEL-A", area: "1")
      first.update_column(:updated_at, 1.day.ago)
      second = create(:location, building: "DEL-B", area: "1")

      get :index
      expect(parsed_body["locations"].map { |l| l["id"] }).to include(first.id, second.id)

      delete :destroy, params: { id: first.id }
      expect(response.status).to eq(200)
      expect(Location.exists?(first.id)).to eq(false)

      get :index
      ids = JSON.parse(response.body)["locations"].map { |l| l["id"] }
      expect(ids).to include(second.id)
      expect(ids).not_to include(first.id)
    end
  end
end
