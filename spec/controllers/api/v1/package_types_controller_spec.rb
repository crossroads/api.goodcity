require "rails_helper"

RSpec.describe Api::V1::PackageTypesController, type: :controller do
  let(:user) { create(:user_with_token, :reviewer) }

  describe "GET package_types" do
    before { generate_and_set_token(user) }

    it "returns 200", show_in_doc: true  do
      create_list :package_type, 3
      get :index
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body["package_types"].size).to eq(3)
    end
  end
end
