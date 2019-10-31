require "rails_helper"

RSpec.describe Api::V1::LookupsController, type: :controller do
  let(:user) { create(:user_with_token, :with_can_manage_package_detail_permission, role_name: "Order Fulfilment") }

  before do
    generate_and_set_token(user)
    10.times.each do |n|
      create(:lookup, name: "lookup_#{n}")
    end
    5.times.each do |n|
      create(:lookup, name: "lookup_11")
    end
  end
  describe "GET lookups" do
    it "returns 200", :show_in_doc do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized lookups" do
      get :index
      body = JSON.parse(response.body)
      expect(body["lookups"].length).to eq(Lookup.count)
    end

    it "returns filtered serialized lookups" do
      get :index, name:"lookup_11"
      body = JSON.parse(response.body)
      expect(body["lookups"].length).to eq(5)
    end
  end
end
