require "rails_helper"

RSpec.describe Api::V1::ItemTypesController, type: :controller do
  let(:user) { create(:user_with_token, :reviewer) }

  describe "GET item_types" do
    before { generate_and_set_token(user) }
    let(:codes) { generate(:item_types).keys.take(3) }

    it "returns 200", show_in_doc: true  do
      codes.each { |code| create :item_type, code: code }
      get :index
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body["item_types"].size).to eq(3)
      codes.each do |code|
        expect(body["item_types"].to_s).to include(code)
      end
    end
  end
end
