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
      codes = JSON.parse(response.body)["package_types"].map { |pt| pt["code"] }
      expect(codes).to include("AFO", "BBC", "BBM")
    end

    it "returns all stock enabled package_types" do
      stock_package_types = [
        create(:base_package_type, allow_package: true, code: "AFO"),
        create(:base_package_type, allow_package: true, code: "BBC"),
        create(:base_package_type, allow_package: true, code: "BBM")
      ]
      donor = stock_package_types.first.reload
      excluded_code = "ZZX#{SecureRandom.hex(4).upcase}"
      package_type = PackageType.create!(
        donor.attributes.except("id", "created_at", "updated_at").merge(
          "code" => excluded_code,
          "allow_package" => false
        )
      )

      get :index, params: { stock: true }, format: 'json'

      expect(response.status).to eq(200)

      package_type_codes = JSON.parse(response.body)["codes"].map{|code| code["code"]}
      expect(package_type_codes).to include(*stock_package_types.map(&:code))
      expect(package_type_codes).not_to include(package_type.code)
    end
  end
end
