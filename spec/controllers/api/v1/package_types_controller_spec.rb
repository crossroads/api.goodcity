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

  describe "GET package_types/:id" do
    let(:package_type) { create(:base_package_type, code: "AFO") }

    it "requires a signed-in user (the admin shape carries usage counts)" do
      get :show, params: { id: package_type.id }
      expect(response.status).to eq(401)
    end

    it "returns the admin shape to a signed-in user" do
      generate_and_set_token(user)
      cat = create(:package_category)
      package_type.package_categories << cat
      get :show, params: { id: package_type.id }

      expect(response.status).to eq(200)
      body = JSON.parse(response.body)["package_type"]
      expect(body).to include("id" => package_type.id, "code" => "AFO",
                              "name_en" => package_type.name_en,
                              "name_zh_tw" => package_type.name_zh_tw,
                              "location_id" => package_type.location_id,
                              "in_use" => false)
      expect(body["package_category_ids"]).to eq([cat.id])
      expect(body["subpackage_types"].first).to include("subpackage_type_id" => package_type.id, "is_default" => true)
    end
  end

  describe "POST package_types" do
    let(:admin) { create(:user, :with_token, :with_can_add_package_types_permission, role_name: "Order fulfilment") }
    let(:location) { create(:location) }

    it "denies a user without the permission" do
      generate_and_set_token(user)
      post :create, params: { package_type: { code: "ZZZ", name_en: "Widget" } }
      expect(response.status).to eq(403)
    end

    context "with permission" do
      before { generate_and_set_token(admin) }

      it "creates a type and auto-adds its self-referential default subpackage", show_in_doc: true do
        cat = create(:package_category)
        expect {
          post :create, params: { package_type: { code: "ZZZ", name_en: "Widget", name_zh_tw: "小部件",
                                                  allow_package: true, location_id: location.id,
                                                  package_category_ids: [cat.id] } }, as: :json
        }.to change(PackageType, :count).by(1)
        pt = PackageType.find_by(code: "ZZZ")
        expect(response.status).to eq(201)
        expect(JSON.parse(response.body)["package_type"]["code"]).to eq("ZZZ")
        expect(pt.package_categories).to eq([cat])
        expect(pt.subpackage_types.where(subpackage_type_id: pt.id, is_default: true)).to exist
      end

      it "422s on a missing code and name" do
        expect {
          post :create, params: { package_type: { name_en: "", code: "" } }
        }.not_to change(PackageType, :count)
        expect(response.status).to eq(422)
        errors = JSON.parse(response.body)
        expect(errors.keys).to include("code", "name_en")
      end

      it "422s on a malformed or duplicate code" do
        create(:base_package_type, code: "AFO")
        post :create, params: { package_type: { code: "afo", name_en: "x" } }
        expect(response.status).to eq(422)
        post :create, params: { package_type: { code: "AFO", name_en: "x" } }
        expect(response.status).to eq(422)
      end
    end
  end

  describe "PATCH package_types/:id" do
    let(:admin) { create(:user, :with_token, :with_can_add_package_types_permission, role_name: "Order fulfilment") }
    let!(:pt) { create(:base_package_type, code: "AFO") }
    before { generate_and_set_token(admin) }

    # The editor sends JSON. apipie's typed params (Integer, [true, false], Array of Integer) reject the
    # strings a form-encoded request carries, so the examples that exercise those params use as: :json.
    it "updates scalars, translations, valuation and the category set" do
      cat = create(:package_category)
      patch :update, params: { id: pt.id, package_type: {
        name_zh_tw: "小部件", customs_value_usd: "12.50", allow_box: true,
        department: "Furniture", length: 10, package_category_ids: [cat.id] } }, as: :json
      expect(response.status).to eq(200)
      pt.reload
      expect(pt.name_zh_tw).to eq("小部件")
      expect(pt.customs_value_usd).to eq(12.5)
      expect(pt.allow_box).to eq(true)
      expect(pt.department).to eq("Furniture")
      expect(pt.package_categories).to eq([cat])
    end

    it "accepts JSON decimals and clears nullable fields with null (what the editor sends)" do
      pt.update_columns(default_value_hk_dollar: 5, length: 3)
      patch :update, params: { id: pt.id, package_type: {
        customs_value_usd: 12.5, default_value_hk_dollar: nil, length: nil } }, as: :json
      expect(response.status).to eq(200)
      pt.reload
      expect(pt.customs_value_usd).to eq(12.5)
      expect(pt.default_value_hk_dollar).to be_nil
      expect(pt.length).to be_nil
    end

    it "clears categories when an empty set is sent" do
      pt.package_categories << create(:package_category)
      patch :update, params: { id: pt.id, package_type: { name_en: pt.name_en, package_category_ids: [] } }, as: :json
      expect(response.status).to eq(200)
      expect(pt.reload.package_categories).to be_empty
    end

    it "422s and changes nothing on invalid data" do
      cat = create(:package_category)
      patch :update, params: { id: pt.id, package_type: { name_en: "", package_category_ids: [cat.id] } }
      expect(response.status).to eq(422)
      expect(pt.reload.package_categories).to be_empty
    end

    it "denies a user without the permission" do
      generate_and_set_token(user)
      patch :update, params: { id: pt.id, package_type: { name_en: "x" } }
      expect(response.status).to eq(403)
    end
  end

  describe "DELETE package_types/:id" do
    let!(:pt) { create(:base_package_type, code: "AFO", allow_package: true, allow_box: true, visible_in_selects: true) }

    it "retires the type (flags off, record kept) for a settings manager" do
      supervisor = create(:user, :with_token, :with_can_manage_settings_permission, role_name: "Supervisor")
      generate_and_set_token(supervisor)
      delete :destroy, params: { id: pt.id }
      expect(response.status).to eq(200)
      pt.reload
      expect([pt.visible_in_selects, pt.allow_package, pt.allow_box, pt.allow_pallet,
              pt.allow_pieces, pt.allow_requests]).to all(eq(false))
    end

    it "denies can_add_package_types only users" do
      admin = create(:user, :with_token, :with_can_add_package_types_permission, role_name: "Order fulfilment")
      generate_and_set_token(admin)
      delete :destroy, params: { id: pt.id }
      expect(response.status).to eq(403)
      expect(pt.reload.allow_package).to eq(true)
    end
  end
end
