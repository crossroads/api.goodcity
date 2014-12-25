require 'rails_helper'

RSpec.describe Api::V1::ItemTypesController, type: :controller do

  let(:user) { create(:user_with_token, :reviewer) }
  let(:item_type) { create(:item_type) }
  let(:serialized_item_type) { Api::V1::ItemTypeSerializer.new(item_type).to_json }
  subject { JSON.parse(response.body) }

  describe "GET item_types" do
    before { generate_and_set_token(user) }

    it "returns 200", show_in_doc: true  do
      3.times { create :item_type }
      get :index
      expect(response.status).to eq(200)
      expect(subject['item_types'].length).to eq(3)
    end
  end
end
