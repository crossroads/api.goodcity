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
      expect(body).to include("set_count" => 0, "deletable" => true)
    end

    it "is not deletable while only a soft-deleted item or package points at it (the foreign key still holds)" do
      generate_and_set_token(user)
      item = create(:item, package_type: package_type)
      Item.where(id: item.id).update_all(deleted_at: Time.current)
      get :show, params: { id: package_type.id }
      body = JSON.parse(response.body)["package_type"]
      expect(body).to include("item_count" => 0, "in_use" => false, "deletable" => false)
    end

    it "is not deletable while a package set points at it" do
      generate_and_set_token(user)
      create(:package_set, package_type: package_type)
      get :show, params: { id: package_type.id }
      body = JSON.parse(response.body)["package_type"]
      expect(body).to include("in_use" => false, "set_count" => 1, "deletable" => false)
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

  # Retire must reach the cached legacy lists: GET /package_types (every type, flags in the body) and
  # GET /package_types?stock=true (visible types only), so the legacy apps stop offering a retired type.
  describe "DELETE package_types/:id and the cached legacy lists" do
    let(:supervisor) { create(:user, :with_token, :with_can_manage_settings_permission, role_name: "Supervisor") }
    let!(:retiring) { create(:base_package_type, code: "AFO", allow_package: true, visible_in_selects: true) }
    let!(:staying) { create(:base_package_type, code: "BBC", allow_package: true, visible_in_selects: true) }

    before do
      Rails.cache.clear
      # An existing type, not the most recently updated row. (update_all, not update_column: the factory's
      # find-or-create leaves id_in_database nil, so update_column/update_columns on it update nothing.)
      PackageType.where(id: retiring.id).update_all(updated_at: 1.day.ago)
      generate_and_set_token(supervisor) # set before the first request: a controller spec keeps that header
    end

    def body_rows(root)
      JSON.parse(response.body)[root]
    end

    it "drops a retired existing type from a warmed ?stock=true and flags it off in the warmed plain index" do
      get :index, params: { stock: true }
      expect(body_rows("codes").map { |r| r["code"] }).to include("AFO", "BBC")
      get :index
      expect(body_rows("package_types").find { |r| r["code"] == "AFO" }["allow_package"]).to eq(true)

      delete :destroy, params: { id: retiring.id }
      expect(response.status).to eq(200)

      get :index, params: { stock: true }
      codes = body_rows("codes").map { |r| r["code"] }
      expect(codes).to include("BBC")
      expect(codes).not_to include("AFO")

      get :index
      row = body_rows("package_types").find { |r| r["code"] == "AFO" }
      expect(row["allow_package"]).to eq(false)
      expect(row["visible_in_selects"]).to eq(false)
    end

    it "writes a paper_trail version for the retire", versioning: true do
      versions = -> { Version.where(item_type: "PackageType", item_id: retiring.id) }
      expect { delete :destroy, params: { id: retiring.id } }.to change { versions.call.count }.by(1)
      version = versions.call.last
      expect(version.event).to eq("update")
      expect(version.whodunnit).to eq(supervisor.id.to_s)
      expect(version.object_changes.keys).to include("allow_package", "visible_in_selects")
    end

    it "retires a legacy row the admin-editor validations would reject" do
      PackageType.where(id: retiring.id).update_all(name_en: nil, code: "afo")
      delete :destroy, params: { id: retiring.id }
      expect(response.status).to eq(200)
      expect(retiring.reload.allow_package).to eq(false)
    end
  end

  # GET /package_categories is a CacheableJson body whose package_type_codes lists each category's types.
  describe "the cached package_categories list follows the editor's changes" do
    let(:admin) { create(:user, :with_token, :with_can_add_package_types_permission, role_name: "Order fulfilment") }
    let!(:pt) { create(:base_package_type, code: "AFO") }
    let!(:cat) { create(:package_category) }

    def cached_codes(category)
      rows = JSON.parse(PackageCategory.cached_json.to_json)["package_categories"]
      rows.find { |r| r["id"] == category.id }["package_type_codes"].split(",")
    end

    before do
      Rails.cache.clear
      pt.package_categories << cat
      cat.update_column(:updated_at, 1.day.ago)
      create(:package_category) # a newer category, so MAX(updated_at) is not cat's
      generate_and_set_token(admin)
    end

    it "drops the type from a category it is removed from" do
      expect(cached_codes(cat)).to include("AFO")
      patch :update, params: { id: pt.id, package_type: { package_category_ids: [] } }, as: :json
      expect(response.status).to eq(200)
      expect(cached_codes(cat)).not_to include("AFO")
    end

    it "shows the new code after the type's code is renamed" do
      expect(cached_codes(cat)).to include("AFO")
      patch :update, params: { id: pt.id, package_type: { code: "AFOX" } }, as: :json
      expect(response.status).to eq(200)
      expect(cached_codes(cat)).to include("AFOX")
      expect(cached_codes(cat)).not_to include("AFO")
    end
  end

  # The goods-types editor's list. Additive: GET /package_types without admin stays the cached legacy body.
  # The containment editor: subpackage_types rows where this type is the parent.
  describe "containment (subpackage_types member actions)" do
    let(:admin) { create(:user, :with_token, :with_can_add_package_types_permission, role_name: "Order fulfilment") }
    # Fresh types, not factory find-or-create ones: after_create gives each its self-default row.
    let!(:parent) { PackageType.create!(code: "ZZPAR", name_en: "Parent box", allow_box: true) }
    let!(:child) { PackageType.create!(code: "ZZCHI", name_en: "Child thing", allow_package: true) }
    let(:row_keys) { %w[id package_type_id subpackage_type_id is_default child_code child_name] }

    def row(child_id = child.id)
      SubpackageType.find_by(package_type_id: parent.id, subpackage_type_id: child_id)
    end

    # cancan's loader keeps @package_type on the controller between requests of one example.
    def next_request!
      @controller = described_class.new
    end

    def error_message
      JSON.parse(response.body)["errors"].first["message"]
    end

    before { generate_and_set_token(admin) }

    it "starts with the server-made self-default row" do
      expect(row(parent.id).is_default).to eq(true)
    end

    it "adds an allowed child, not default by default", show_in_doc: true do
      expect {
        post :add_subpackage_type, params: { id: parent.id, subpackage_type: { subpackage_type_id: child.id } }, as: :json
      }.to change(SubpackageType, :count).by(1)
      expect(response.status).to eq(201)
      body = JSON.parse(response.body)["subpackage_type"]
      expect(body.keys).to match_array(row_keys)
      expect(body).to include("package_type_id" => parent.id, "subpackage_type_id" => child.id,
                              "is_default" => false, "child_code" => "ZZCHI", "child_name" => "Child thing")
      expect(row.is_default).to eq(false)
    end

    it "adds a child as default content when asked" do
      post :add_subpackage_type, params: { id: parent.id, subpackage_type: { subpackage_type_id: child.id, is_default: true } }, as: :json
      expect(response.status).to eq(201)
      expect(row.is_default).to eq(true)
    end

    it "422s on a child that is already allowed (one row per parent and child)" do
      SubpackageType.create!(package_type: parent, child_package_type: child)
      expect {
        post :add_subpackage_type, params: { id: parent.id, subpackage_type: { subpackage_type_id: child.id } }, as: :json
      }.not_to change(SubpackageType, :count)
      expect(response.status).to eq(422)
      expect(error_message).to eq("ZZCHI is already allowed inside ZZPAR")
    end

    it "422s on adding the type to itself again (its self row exists)" do
      post :add_subpackage_type, params: { id: parent.id, subpackage_type: { subpackage_type_id: parent.id } }, as: :json
      expect(response.status).to eq(422)
      expect(SubpackageType.where(package_type_id: parent.id, subpackage_type_id: parent.id).count).to eq(1)
    end

    it "422s on a child type that does not exist" do
      expect {
        post :add_subpackage_type, params: { id: parent.id, subpackage_type: { subpackage_type_id: 999_999 } }, as: :json
      }.not_to change(SubpackageType, :count)
      expect(response.status).to eq(422)
    end

    it "422s without a subpackage_type_id" do
      post :add_subpackage_type, params: { id: parent.id, subpackage_type: { is_default: true } }, as: :json
      expect(response.status).to eq(422)
    end

    it "sets and unsets default on an allowed child" do
      SubpackageType.create!(package_type: parent, child_package_type: child, is_default: false)
      patch :set_subpackage_default, params: { id: parent.id, child_id: child.id, is_default: true }, as: :json
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)["subpackage_type"]).to include("subpackage_type_id" => child.id, "is_default" => true)
      expect(row.is_default).to eq(true)

      next_request!
      put :set_subpackage_default, params: { id: parent.id, child_id: child.id, is_default: false }, as: :json
      expect(response.status).to eq(200)
      expect(row.is_default).to eq(false)
    end

    it "422s when is_default is missing or not a boolean" do
      SubpackageType.create!(package_type: parent, child_package_type: child, is_default: false)
      patch :set_subpackage_default, params: { id: parent.id, child_id: child.id }, as: :json
      expect(response.status).to eq(422)
      next_request!
      patch :set_subpackage_default, params: { id: parent.id, child_id: child.id, is_default: "soon" }, as: :json
      expect(response.status).to eq(422)
      expect(row.is_default).to eq(false)
    end

    it "refuses to switch off the self-default, and accepts switching it on" do
      patch :set_subpackage_default, params: { id: parent.id, child_id: parent.id, is_default: false }, as: :json
      expect(response.status).to eq(422)
      expect(error_message).to match(/itself as its default content/)
      expect(row(parent.id).is_default).to eq(true)

      next_request!
      patch :set_subpackage_default, params: { id: parent.id, child_id: parent.id, is_default: true }, as: :json
      expect(response.status).to eq(200)
    end

    it "404s setting default on a child that is not allowed" do
      patch :set_subpackage_default, params: { id: parent.id, child_id: child.id, is_default: true }, as: :json
      expect(response.status).to eq(404)
    end

    it "removes an allowed child (the child type itself stays)" do
      SubpackageType.create!(package_type: parent, child_package_type: child)
      delete :remove_subpackage_type, params: { id: parent.id, child_id: child.id }
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to eq({})
      expect(row).to be_nil
      expect(PackageType.exists?(child.id)).to eq(true)
      expect(row(parent.id)).to be_present
    end

    it "refuses to remove the self-default" do
      delete :remove_subpackage_type, params: { id: parent.id, child_id: parent.id }
      expect(response.status).to eq(422)
      expect(error_message).to match(/itself as its default content/)
      expect(row(parent.id)).to be_present
    end

    it "404s removing a child that is not allowed" do
      delete :remove_subpackage_type, params: { id: parent.id, child_id: child.id }
      expect(response.status).to eq(404)
    end

    it "only touches rows where this type is the parent" do
      other = PackageType.create!(code: "ZZOTH", name_en: "Other box", allow_box: true)
      SubpackageType.create!(package_type: other, child_package_type: child)
      delete :remove_subpackage_type, params: { id: parent.id, child_id: child.id }
      expect(response.status).to eq(404)
      expect(SubpackageType.where(package_type_id: other.id, subpackage_type_id: child.id)).to exist
    end

    context "a legacy type with no self row and two defaults (like FWT: FTD and FCD)" do
      let!(:other) { PackageType.create!(code: "ZZOTH", name_en: "Other part", allow_package: true) }

      before do
        SubpackageType.where(package_type_id: parent.id).delete_all
        SubpackageType.create!(package_type: parent, child_package_type: child, is_default: true)
        SubpackageType.create!(package_type: parent, child_package_type: other, is_default: true)
      end

      it "may switch one default off, but never the last one" do
        patch :set_subpackage_default, params: { id: parent.id, child_id: child.id, is_default: false }, as: :json
        expect(response.status).to eq(200)
        next_request!
        patch :set_subpackage_default, params: { id: parent.id, child_id: other.id, is_default: false }, as: :json
        expect(response.status).to eq(422)
        expect(error_message).to eq("ZZOTH is the only default content of ZZPAR, so it can't be switched off: make another type default first")
        expect(row(other.id).is_default).to eq(true)
      end

      it "may remove one default, but never the last one; a non-default row always goes" do
        delete :remove_subpackage_type, params: { id: parent.id, child_id: child.id }
        expect(response.status).to eq(200)
        next_request!
        delete :remove_subpackage_type, params: { id: parent.id, child_id: other.id }
        expect(response.status).to eq(422)
        expect(error_message).to match(/ZZOTH is the only default content of ZZPAR, so it can't be removed/)
        expect(row(other.id)).to be_present
      end

      it "adding the type to itself makes a DEFAULT self row, whatever was asked" do
        post :add_subpackage_type, params: { id: parent.id, subpackage_type: { subpackage_type_id: parent.id, is_default: false } }, as: :json
        expect(response.status).to eq(201)
        expect(JSON.parse(response.body)["subpackage_type"]["is_default"]).to eq(true)
        expect(row(parent.id).is_default).to eq(true)
      end
    end

    it "denies a user without the permission" do
      generate_and_set_token(user)
      post :add_subpackage_type, params: { id: parent.id, subpackage_type: { subpackage_type_id: child.id } }, as: :json
      expect(response.status).to eq(403)
      next_request!
      delete :remove_subpackage_type, params: { id: parent.id, child_id: parent.id }
      expect(response.status).to eq(403)
      expect(row).to be_nil
    end
  end

  # GET /package_types and ?stock=true are cached (CacheableJson) and embed each type's child codes
  # (default_child_packages / other_child_packages, for a signed-in reader). A containment write must
  # move their key, or the legacy apps keep the old containment until some unrelated type changes.
  describe "containment writes and the cached legacy lists" do
    let(:admin) { create(:user, :with_token, :with_can_add_package_types_permission, role_name: "Order fulfilment") }
    let!(:parent) { PackageType.create!(code: "ZZPAR", name_en: "Parent box", allow_box: true) }
    let!(:child) { PackageType.create!(code: "ZZCHI", name_en: "Child thing", allow_package: true) }
    let!(:newest) { PackageType.create!(code: "ZZNEW", name_en: "Newest", allow_package: true) }

    before do
      Rails.cache.clear
      # The parent is not the most recently updated row, so only a deliberate re-key moves MAX(updated_at).
      PackageType.where(id: [parent.id, child.id]).update_all(updated_at: 1.day.ago)
      generate_and_set_token(admin)
    end

    def next_request!
      @controller = described_class.new
    end

    def parent_row(root)
      JSON.parse(response.body)[root].find { |r| r["id"] == parent.id }
    end

    def contains(root)
      r = parent_row(root)
      { default: r["default_child_packages"].split(",").sort, other: r["other_child_packages"].split(",").sort }
    end

    def read_both
      next_request!
      get :index
      plain = contains("package_types")
      next_request!
      get :index, params: { stock: true }
      [plain, contains("codes")]
    end

    it "shows each add, default switch and removal in both warmed lists" do
      expect(read_both).to all(eq(default: ["ZZPAR"], other: []))

      next_request!
      post :add_subpackage_type, params: { id: parent.id, subpackage_type: { subpackage_type_id: child.id } }, as: :json
      expect(response.status).to eq(201)
      expect(read_both).to all(eq(default: ["ZZPAR"], other: ["ZZCHI"]))

      next_request!
      patch :set_subpackage_default, params: { id: parent.id, child_id: child.id, is_default: true }, as: :json
      expect(response.status).to eq(200)
      expect(read_both).to all(eq(default: %w[ZZCHI ZZPAR], other: []))

      next_request!
      delete :remove_subpackage_type, params: { id: parent.id, child_id: child.id }
      expect(response.status).to eq(200)
      expect(read_both).to all(eq(default: ["ZZPAR"], other: []))
    end

    it "writes no PackageType version for the re-key, and a SubpackageType version for each change", versioning: true do
      pt_versions = -> { Version.where(item_type: "PackageType").count }
      before = Version.maximum(:id) || 0 # the let! types' own self rows were versioned as they were made
      sub_versions = -> { Version.where(item_type: "SubpackageType").where("id > ?", before).order(:id) }
      expect {
        post :add_subpackage_type, params: { id: parent.id, subpackage_type: { subpackage_type_id: child.id } }, as: :json
        next_request!
        patch :set_subpackage_default, params: { id: parent.id, child_id: child.id, is_default: true }, as: :json
        next_request!
        delete :remove_subpackage_type, params: { id: parent.id, child_id: child.id }
      }.not_to change { pt_versions.call }
      expect(sub_versions.call.pluck(:event)).to eq(%w[create update destroy])
      expect(sub_versions.call.pluck(:whodunnit).uniq).to eq([admin.id.to_s])
      expect(sub_versions.call.last.object).to include("package_type_id" => parent.id, "subpackage_type_id" => child.id)
    end

    it "leaves the cache key alone when the write is refused" do
      key = PackageType.cache_key
      delete :remove_subpackage_type, params: { id: parent.id, child_id: parent.id }
      expect(response.status).to eq(422)
      expect(PackageType.cache_key).to eq(key)
    end
  end

  describe "DELETE package_types/:id?hard=true" do
    let(:supervisor) { create(:user, :with_token, :with_can_manage_settings_permission, role_name: "Supervisor") }
    let!(:pt) { PackageType.create!(code: "ZZDEL", name_en: "Made in error", allow_package: true) }

    before { generate_and_set_token(supervisor) }

    def error_message
      JSON.parse(response.body)["errors"].first["message"]
    end

    it "deletes a never-used type with its containment rows on both sides and its category joins", versioning: true do
      box = PackageType.create!(code: "ZZBOX", name_en: "Box", allow_box: true)
      inner = PackageType.create!(code: "ZZINN", name_en: "Inner", allow_package: true)
      SubpackageType.create!(package_type: box, child_package_type: pt)    # pt is a child of box
      SubpackageType.create!(package_type: pt, child_package_type: inner)  # pt is a parent of inner
      cat = create(:package_category)
      pt.package_categories << cat

      delete :destroy, params: { id: pt.id, hard: "true" }

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to eq({})
      expect(PackageType.exists?(pt.id)).to eq(false)
      expect(SubpackageType.where(package_type_id: pt.id)).to be_empty
      expect(SubpackageType.where(subpackage_type_id: pt.id)).to be_empty
      expect(PackageCategoriesPackageType.where(package_type_id: pt.id)).to be_empty
      expect(PackageCategory.exists?(cat.id)).to eq(true)
      expect(PackageType.exists?(box.id) && PackageType.exists?(inner.id)).to eq(true)
      expect(SubpackageType.where(package_type_id: box.id, subpackage_type_id: box.id)).to exist
      version = Version.where(item_type: "PackageType", item_id: pt.id, event: "destroy").last
      expect(version).to be_present
      expect(version.whodunnit).to eq(supervisor.id.to_s)
    end

    {
      "an item" => ->(pt) { create(:item, package_type: pt) },
      "a package" => ->(pt) { create(:package, package_type: pt) },
      "a goodcity request" => ->(pt) { create(:goodcity_request, package_type: pt) },
      "a package set" => ->(pt) { create(:package_set, package_type: pt) }
    }.each do |what, make|
      it "refuses while #{what} points at it, and changes nothing" do
        instance_exec(pt, &make)
        delete :destroy, params: { id: pt.id, hard: "true" }
        expect(response.status).to eq(422)
        expect(error_message).to match(/ZZDEL is in use .*retire it instead/)
        pt.reload
        expect(pt.allow_package).to eq(true) # not retired either
        expect(SubpackageType.where(package_type_id: pt.id, subpackage_type_id: pt.id)).to exist
      end
    end

    {
      "a soft-deleted item" => ->(pt) { Item.where(id: create(:item, package_type: pt).id).update_all(deleted_at: Time.current) },
      "a soft-deleted package" => ->(pt) { Package.where(id: create(:package, package_type: pt).id).update_all(deleted_at: Time.current) }
    }.each do |what, make|
      it "refuses while only #{what} points at it (counted, not left to the foreign key)" do
        instance_exec(pt, &make)
        delete :destroy, params: { id: pt.id, hard: "true" }
        expect(response.status).to eq(422)
        expect(error_message).to match(/ZZDEL is in use .*retire it instead/)
        expect(PackageType.exists?(pt.id)).to eq(true)
      end
    end

    it "refuses while it is some parent's ONLY default content, and goes once that parent has another" do
      set = PackageType.create!(code: "ZZSET", name_en: "A set", allow_package: true)
      SubpackageType.where(package_type_id: set.id).delete_all # a legacy type with no self row
      SubpackageType.create!(package_type: set, child_package_type: pt, is_default: true)
      delete :destroy, params: { id: pt.id, hard: "true" }
      expect(response.status).to eq(422)
      expect(error_message).to eq("ZZDEL is the only default content of ZZSET; make another type default there first")
      expect(PackageType.exists?(pt.id)).to eq(true)

      other = PackageType.create!(code: "ZZPRT", name_en: "Part", allow_package: true)
      SubpackageType.create!(package_type: set, child_package_type: other, is_default: true)
      @controller = described_class.new
      delete :destroy, params: { id: pt.id, hard: "true" }
      expect(response.status).to eq(200)
      expect(SubpackageType.where(package_type_id: set.id).pluck(:subpackage_type_id)).to eq([other.id])
    end

    it "retires (does not delete) unless hard is exactly true" do
      delete :destroy, params: { id: pt.id, hard: "1" }
      expect(response.status).to eq(200)
      expect(PackageType.exists?(pt.id)).to eq(true)
      expect(pt.reload.allow_package).to eq(false)
    end

    it "denies a can_add_package_types only user" do
      admin = create(:user, :with_token, :with_can_add_package_types_permission, role_name: "Order fulfilment")
      generate_and_set_token(admin)
      delete :destroy, params: { id: pt.id, hard: "true" }
      expect(response.status).to eq(403)
      expect(PackageType.exists?(pt.id)).to eq(true)
    end

    it "drops the deleted code from the parents' rows in the warmed legacy lists" do
      box = PackageType.create!(code: "ZZBOX", name_en: "Box", allow_box: true)
      SubpackageType.create!(package_type: box, child_package_type: pt)
      # pt is retired (outside ?stock=true) and neither row is the newest, so neither MAX nor the
      # visible count would move on their own.
      PackageType.where(id: pt.id).update_all(allow_package: false, visible_in_selects: false)
      PackageType.where(id: [pt.id, box.id]).update_all(updated_at: 1.day.ago)
      PackageType.create!(code: "ZZNEW", name_en: "Newest", allow_package: true)
      Rails.cache.clear

      box_row = ->(root) { JSON.parse(response.body)[root].find { |r| r["id"] == box.id } }
      get :index, params: { stock: true }
      expect(box_row.call("codes")["other_child_packages"]).to eq("ZZDEL")
      @controller = described_class.new
      get :index
      expect(box_row.call("package_types")["other_child_packages"]).to eq("ZZDEL")

      @controller = described_class.new
      delete :destroy, params: { id: pt.id, hard: "true" }
      expect(response.status).to eq(200)

      @controller = described_class.new
      get :index, params: { stock: true }
      expect(box_row.call("codes")["other_child_packages"]).to eq("")
      @controller = described_class.new
      get :index
      expect(box_row.call("package_types")["other_child_packages"]).to eq("")
      expect(JSON.parse(response.body)["package_types"].map { |r| r["id"] }).not_to include(pt.id)
    end
  end

  describe "GET package_types?admin=true" do
    let(:admin) { create(:user, :with_token, :with_can_add_package_types_permission, role_name: "Order fulfilment") }
    let(:admin_row_keys) do
      %w[id code name_en name_zh_tw other_terms_en other_terms_zh_tw department location_id subform
         allow_package allow_pieces allow_box allow_pallet allow_requests visible_in_selects allow_expiry_date
         package_category_ids in_use item_count package_count request_count]
    end

    def count_queries(&block)
      n = 0
      counter = lambda do |*, payload|
        next if %w[SCHEMA TRANSACTION].include?(payload[:name]) || payload[:cached]
        next if payload[:sql] =~ /\A\s*(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/i
        n += 1
      end
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
      n
    end

    it "401s without a token" do
      get :index, params: { admin: "true" }
      expect(response.status).to eq(401)
    end

    it "403s for a signed-in user who cannot update package types" do
      generate_and_set_token(user)
      get :index, params: { admin: "true" }
      expect(response.status).to eq(403)
    end

    it "returns the lean admin rows with department, both languages, categories and usage", show_in_doc: true do
      generate_and_set_token(admin)
      used = create(:base_package_type, code: "AFO", department: "Food", name_zh_tw: "食品")
      unused = create(:base_package_type, code: "BBC")
      cat = create(:package_category)
      used.package_categories << cat
      create(:item, package_type: used)

      get :index, params: { admin: "true" }
      expect(response.status).to eq(200)
      rows = JSON.parse(response.body)["package_types"]
      row = rows.find { |r| r["code"] == "AFO" }
      expect(row.keys).to match_array(admin_row_keys)
      expect(row).to include("id" => used.id, "name_en" => used.name_en, "name_zh_tw" => "食品",
                             "other_terms_en" => used.other_terms_en, "other_terms_zh_tw" => used.other_terms_zh_tw,
                             "department" => "Food", "location_id" => used.location_id,
                             "package_category_ids" => [cat.id], "in_use" => true, "item_count" => 1,
                             "package_count" => 0, "request_count" => 0)
      expect(rows.find { |r| r["code"] == "BBC" }).to include("in_use" => false, "package_category_ids" => [])
      expect(rows.map { |r| r["id"] }).to include(unused.id)
    end

    it "is not cached: a change that does not move updated_at still shows" do
      generate_and_set_token(admin)
      pt = create(:base_package_type, code: "AFO", department: "Food")
      get :index, params: { admin: "true" }
      PackageType.where(id: pt.id).update_all(department: "Furniture")
      get :index, params: { admin: "true" }
      row = JSON.parse(response.body)["package_types"].find { |r| r["code"] == "AFO" }
      expect(row["department"]).to eq("Furniture")
    end

    it "runs the same number of queries for 2 rows as for 6 (batched usage and categories)" do
      generate_and_set_token(admin)
      cat = create(:package_category)
      make = lambda do |codes|
        codes.each do |code|
          t = create(:base_package_type, code: code)
          t.package_categories << cat
          create(:item, package_type: t)
        end
      end
      make.call(%w[AFO BBC])
      get :index, params: { admin: "true" } # warm-up (auth lookups, schema)
      small = count_queries { get :index, params: { admin: "true" } }
      make.call(%w[BBM BBS BCB BCM])
      large = count_queries { get :index, params: { admin: "true" } }
      expect(JSON.parse(response.body)["package_types"].size).to be >= 6
      expect(large).to eq(small)
    end

    it "leaves the plain index on the legacy shape" do
      generate_and_set_token(admin)
      create(:base_package_type, code: "AFO", department: "Food")
      get :index
      row = JSON.parse(response.body)["package_types"].find { |r| r["code"] == "AFO" }
      expect(row).not_to have_key("department")
      expect(row).not_to have_key("name_zh_tw")
      expect(row).not_to have_key("in_use")
    end
  end
end
