require "rails_helper"

RSpec.describe Api::V1::PackageTypesController, type: :controller do
  let(:user) { create(:user, :with_token, :reviewer) }

  describe "GET package_types" do
    before { generate_and_set_token(user) }

    it "returns all package_types", show_in_doc: true  do
      create_list :base_package_type, 3

      get :index

      expect(response.status).to eq(200)
      expect(response.body).to include("package_types")
      expect(JSON.parse(response.body)["package_types"].count).to eq(3)
    end

    it "returns all stock enabled package_types" do
      stock_package_types = create_list :base_package_type, 3, allow_stock: true
      package_type = create :base_package_type

      get :index, params: { stock: true }, format: 'json'

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)["codes"].count).to eq(3)

      package_type_codes = JSON.parse(response.body)["codes"].map{|code| code["code"]}
      expect(package_type_codes).to match_array(stock_package_types.map &:code)
      expect(package_type_codes).to_not include(package_type.code)
    end
  end
end
