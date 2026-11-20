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

  # Retire, not delete: a retired location stays on every record, plain GET /locations still lists it unchanged
  # (the legacy apps' read), and only the new app's opt-in reads (exclude_retired=true) leave it out.
  describe "retire and unretire (PATCH locations/:id location: { retired })" do
    let!(:location) { create(:location, building: "RET-A", area: "1") }

    it "retires: sets retired_at and replies with the admin row", :show_in_doc do
      patch :update, params: { id: location.id, location: { retired: true } }, as: :json
      expect(response.status).to eq(200)
      expect(location.reload.retired_at).to be_present
      row = parsed_body["location"]
      expect(row["retired_at"]).to be_present
      expect(row.keys).to match_array(%w[id building area packages_count printer_name retired_at in_use])
    end

    it "retiring again keeps the first stamp" do
      stamp = 2.days.ago.change(usec: 0)
      location.update_column(:retired_at, stamp)
      patch :update, params: { id: location.id, location: { retired: true } }, as: :json
      expect(response.status).to eq(200)
      expect(location.reload.retired_at).to eq(stamp)
    end

    it "unretires: clears retired_at" do
      location.update_column(:retired_at, 1.day.ago)
      patch :update, params: { id: location.id, location: { retired: false } }, as: :json
      expect(response.status).to eq(200)
      expect(location.reload.retired_at).to be_nil
      expect(parsed_body["location"]["retired_at"]).to be_nil
    end

    it "renames a retired location, which stays retired" do
      location.update_column(:retired_at, 1.day.ago)
      patch :update, params: { id: location.id, location: { building: "RET-B", area: "2" } }, as: :json
      expect(response.status).to eq(200)
      expect(location.reload.building).to eq("RET-B")
      expect(location.retired_at).to be_present
    end

    it "keeps every record that points at it" do
      package = create(:package)
      create(:packages_location, location: location, package: package, quantity: 1)
      create(:packages_inventory, location: location, package: package)
      held = PackagesLocation.where(location_id: location.id).count
      history = PackagesInventory.where(location_id: location.id).count
      expect(history).to be >= 1
      patch :update, params: { id: location.id, location: { retired: true } }, as: :json
      expect(response.status).to eq(200)
      expect(PackagesLocation.where(location_id: location.id).count).to eq(held)
      expect(PackagesInventory.where(location_id: location.id).count).to eq(history)
      expect(parsed_body["location"]["in_use"]).to eq(true)
      expect(parsed_body["location"]["packages_count"]).to eq(1)
    end

    it "rejects a value that isn't a boolean" do
      patch :update, params: { id: location.id, location: { retired: "soon" } }, as: :json
      expect(response.status).to eq(422)
      expect(location.reload.retired_at).to be_nil
    end

    it "does not let POST /locations (the shared create) set retired" do
      post :create, params: { location: { building: "RET-NEW", area: "1", retired: true } }, as: :json
      expect(response.status).to eq(201)
      expect(Location.find_by(building: "RET-NEW").retired_at).to be_nil
      expect(parsed_body["location"].keys).to match_array(%w[id building area])
    end

    context "as a user who cannot manage locations" do
      let(:normal_user) { create(:user, :with_token, role_name: 'Reviewer') }
      before { generate_and_set_token(normal_user) }

      it "returns 403 and leaves it live" do
        patch :update, params: { id: location.id, location: { retired: true } }, as: :json
        expect(response.status).to eq(403)
        expect(location.reload.retired_at).to be_nil
      end
    end
  end

  describe "with_counts rows: retired_at and in_use" do
    let!(:free) { create(:location, building: "USE-FREE", area: "1") }
    let!(:retired) { create(:location, building: "USE-RET", area: "1", retired_at: 1.day.ago) }

    def row_for(loc)
      parsed_body["locations"].find { |l| l["id"] == loc.id }
    end

    it "lists retired locations too, with retired_at" do
      get :index, params: { with_counts: true }
      expect(row_for(retired)["retired_at"]).to be_present
      expect(row_for(free)["retired_at"]).to be_nil
    end

    it "in_use is false only when no foreign key points at the location" do
      by_stock = create(:location, building: "USE-PL", area: "1")
      create(:packages_location, location: by_stock, package: create(:package), quantity: 1)
      by_history = create(:location, building: "USE-PI", area: "1")
      create(:packages_inventory, location: by_history)
      by_stocktake = create(:location, building: "USE-ST", area: "1")
      create(:stocktake, location: by_stocktake)
      by_printer = create(:location, building: "USE-PR", area: "1")
      create(:printer, location: by_printer)
      by_type = create(:location, building: "USE-PT", area: "1")
      PackageType.where(id: create(:package_type).id).update_all(location_id: by_type.id)

      get :index, params: { with_counts: true }
      expect(row_for(free)["in_use"]).to eq(false)
      [by_stock, by_history, by_stocktake, by_printer, by_type].each do |loc|
        expect(row_for(loc)["in_use"]).to eq(true), "#{loc.building} should be in use"
      end
    end

    # One DELETE per example: cancan's load_resource keeps @location across requests in a controller spec, and a
    # refused DELETE's foreign-key error aborts the spec's wrapping transaction.
    it "in_use true matches DELETE's 409" do
      used = create(:location, building: "USE-DEL", area: "1")
      create(:packages_inventory, location: used)
      get :index, params: { with_counts: true }
      expect(row_for(used)["in_use"]).to eq(true)
      @controller = described_class.new
      delete :destroy, params: { id: used.id }
      expect(response.status).to eq(409)
    end

    it "in_use false matches DELETE's 200" do
      get :index, params: { with_counts: true }
      expect(row_for(free)["in_use"]).to eq(false)
      @controller = described_class.new
      delete :destroy, params: { id: free.id }
      expect(response.status).to eq(200)
      expect(Location.exists?(free.id)).to eq(false)
    end
  end

  describe "exclude_retired=true (the new app's opt-in reads)" do
    before { Rails.cache.clear }
    let!(:live) { create(:location, building: "EXC-LIVE", area: "1") }
    let!(:retired) { create(:location, building: "EXC-RET", area: "1", retired_at: 1.day.ago) }

    def ids
      JSON.parse(response.body)["locations"].map { |l| l["id"] }
    end

    it "the plain list leaves retired rows out, in the same lean shape" do
      get :index, params: { exclude_retired: "true" }
      expect(response.status).to eq(200)
      expect(ids).to include(live.id)
      expect(ids).not_to include(retired.id)
      expect(ids).to eq(Location.where(retired_at: nil).order(:id).pluck(:id))
      body = JSON.parse(response.body)
      expect(body.keys).to eq(["locations"])
      body["locations"].each { |row| expect(row.keys).to match_array(%w[id building area]) }
    end

    it "only the string 'true' opts in" do
      get :index, params: { exclude_retired: "false" }
      expect(ids).to include(retired.id)
    end

    it "searchText leaves retired rows out, and keeps its meta" do
      get :index, params: { searchText: "EXC-", exclude_retired: "true" }
      expect(ids).to eq([live.id])
      expect(parsed_body["meta"]).to eq("total_pages" => 1, "search" => "EXC-")

      get :index, params: { searchText: "EXC-" }
      expect(ids).to match_array([live.id, retired.id])
    end

    it "recently_used leaves retired rows out" do
      [retired, live].each do |loc|
        Version.create!(item_type: "Package", item_id: 1, event: "update", whodunnit: reviewer.id.to_s,
                        object_changes: { "location_id" => [nil, loc.id] })
      end
      get :index, params: { recently_used: "true" }
      expect(ids).to match_array([live.id, retired.id])
      get :index, params: { recently_used: "true", exclude_retired: "true" }
      expect(ids).to eq([live.id])
    end

    it "with_counts honours it too" do
      get :index, params: { with_counts: true, exclude_retired: "true" }
      expect(ids).to include(live.id)
      expect(ids).not_to include(retired.id)
    end

    it "never touches the legacy cache: the opt-in read neither writes nor reads the cached body" do
      expect(Location).not_to receive(:cached_json)
      expect(Location).not_to receive(:cache_json)
      get :index, params: { exclude_retired: "true" }
      expect(response.status).to eq(200)
      expect(Rails.cache.exist?(Location.cache_key)).to eq(false)
    end

    it "a warm legacy cache does not leak into the opt-in read" do
      get :index
      expect(ids).to include(retired.id)
      get :index, params: { exclude_retired: "true" }
      expect(ids).not_to include(retired.id)
      get :index
      expect(ids).to include(retired.id)
    end
  end

  # The legacy apps' plain GET /locations: byte-for-byte the shared serializer over every row, retired ones
  # included, before and after a retire, and a retire re-keys the cached body.
  describe "the plain cached GET locations with retired rows present" do
    before { Rails.cache.clear }

    def legacy_body
      ActiveModel::ArraySerializer.new(Location.all, each_serializer: Api::V1::LocationSerializer, root: "locations").to_json
    end

    it "is exactly the shared serializer over every row, retired ones included" do
      create(:location, building: "BYTE-A", area: "1")
      create(:location, building: "BYTE-R", area: "1", retired_at: 1.day.ago)
      get :index
      expect(response.body).to eq(legacy_body)
      expect(JSON.parse(response.body)["locations"].map { |l| l["building"] }).to include("BYTE-R")
    end

    it "a retire re-keys the cache and the retired row stays, unchanged" do
      older = create(:location, building: "BUST-A", area: "1")
      older.update_column(:updated_at, 1.day.ago)
      create(:location, building: "BUST-B", area: "1")

      get :index
      before = JSON.parse(response.body)["locations"].sort_by { |l| l["id"] }
      key_before = Location.cache_key

      patch :update, params: { id: older.id, location: { retired: true } }, as: :json
      expect(response.status).to eq(200)
      expect(Location.cache_key).not_to eq(key_before)

      get :index
      expect(response.body).to eq(legacy_body)
      after = JSON.parse(response.body)["locations"].sort_by { |l| l["id"] }
      expect(after).to eq(before)
      expect(after.find { |l| l["id"] == older.id }.keys).to match_array(%w[id building area])
    end

    it "a renamed retired location shows its new name in the plain list" do
      older = create(:location, building: "REN-A", area: "1", retired_at: 1.day.ago)
      older.update_column(:updated_at, 1.day.ago)
      create(:location, building: "REN-B", area: "1")
      get :index
      patch :update, params: { id: older.id, location: { building: "REN-C" } }, as: :json
      get :index
      row = JSON.parse(response.body)["locations"].find { |l| l["id"] == older.id }
      expect(row["building"]).to eq("REN-C")
    end
  end
end
