require 'rails_helper'

RSpec.describe Api::V1::PackagesController, type: :controller do

  let(:user) { create(:user_with_token) }
  let(:offer) { create :offer, created_by: user }
  let(:item)  { create :item, offer: offer }
  subject { JSON.parse(response.body) }

  describe "GET packages" do
    before { generate_and_set_token(user) }

    it "return serialized packages", :show_in_doc do
      pending "error in postgres_ext-serializers but not currently used"
      2.times { create :package, item: item }
      get :index
      expect(response.status).to eq(200)
      expect(subject['packages'].length).to eq(2)
    end
  end
end
