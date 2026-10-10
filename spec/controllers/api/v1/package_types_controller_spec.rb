require "rails_helper"

RSpec.describe Api::V1::PackageTypesController, type: :controller do
  let(:user) { create(:user, :with_token, :reviewer) }

  describe "GET package_types" do
    before { generate_and_set_token(user) }

    it "returns all package_types", show_in_doc: true  do
      create(:base_package_type, allow_package: true, code: "AFO")
      create(:base_package_type, allow_package: true, code: "BBC")
      create(:base_package_type, allow_package: true, code: "BBM")

      get :index

      expect(response.status).to eq(200)
      expect(response.body).to include("package_types")
      expect(JSON.parse(response.body)["package_types"].count).to eq(3)
    end

    it "returns all stock enabled package_types" do
      stock_package_types = [
        create(:base_package_type, allow_package: true, code: "AFO"),
        create(:base_package_type, allow_package: true, code: "BBC"),
        create(:base_package_type, allow_package: true, code: "BBM")
      ]
      package_type = create(:base_package_type, allow_package: false, code: "BCS")

      get :index, params: { stock: true }, format: 'json'

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)["codes"].count).to eq(3)

      package_type_codes = JSON.parse(response.body)["codes"].map{|code| code["code"]}
      expect(package_type_codes).to match_array(stock_package_types.map &:code)
      expect(package_type_codes).to_not include(package_type.code)
    end
  end

  # The cached bodies sideload each type's default location, so renaming a location has to re-key them.
  describe "GET package_types after a default location is renamed" do
    before do
      Rails.cache.clear
      generate_and_set_token(user)
    end

    let(:location) { create(:location, building: "PTREN", area: "Old") }
    let!(:package_type) { create(:base_package_type, allow_package: true, code: "PTR", location: location) }
    let!(:other_type) { create(:base_package_type, allow_package: true, code: "PTO") }

    def location_names(body)
      JSON.parse(body)["locations"].select { |l| l["building"] == "PTREN" }.map { |l| l["area"] }
    end

    it "shows the new name in the plain index and the stock index" do
      get :index
      expect(location_names(response.body)).to eq(["Old"])
      get :index, params: { stock: true }, format: "json"
      expect(location_names(response.body)).to eq(["Old"])

      location.update!(area: "New")

      get :index
      expect(location_names(response.body)).to eq(["New"])
      get :index, params: { stock: true }, format: "json"
      expect(location_names(response.body)).to eq(["New"])
    end

    it "a retire leaves the cached body alone (nothing it embeds changed)" do
      get :index
      key = PackageType.cache_key
      location.update!(retired: true)
      expect(PackageType.cache_key).to eq(key)
    end
  end
end
