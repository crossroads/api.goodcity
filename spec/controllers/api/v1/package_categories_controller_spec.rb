require "rails_helper"

RSpec.describe Api::V1::PackageCategoriesController, type: :controller do

  describe "GET package_categories" do
    it "returns 200", show_in_doc: true  do
      create_list :child_package_category, 3
      get :index
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body["package_categories"].size).to eq(6)
    end
  end

end
