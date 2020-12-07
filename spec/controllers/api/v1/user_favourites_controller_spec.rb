require 'rails_helper'

RSpec.describe Api::V1::UserFavouritesController, type: :controller do
  let!(:user) { create(:user, :with_token, :with_can_manage_packages_permission) }
  let(:user1) { create(:user) }
  let!(:user_favourite) { create(:user_favourite, user: user) }
  let!(:user_favourite1) { create(:user_favourite) }
  let(:parsed_body) { JSON.parse(response.body) }

  describe "GET user_favourit" do
    before(:each) do
      generate_and_set_token(user) 
      current_user = user
    end

    it "returns 200", :show_in_doc do
      get :index
      expect(response.status).to eq(200)
      expect(parsed_body['user_favourites'].length).to eq(1)
    end

    it "returns user_favourites of logged in user" do
      get :index
      expect(response.status).to eq(200)
      expect(parsed_body['user_favourites'].length).to eq(1)
      expect(parsed_body['user_favourites'][0]["user_id"]).to eq(user.id)
    end

    it "returns user_favourites of logged in user" do
      get :index
      expect(response.status).to eq(200)
      expect(parsed_body['user_favourites'].length).to eq(1)
      expect(parsed_body['user_favourites'][0]["user_id"]).to_not eq(user1.id)
    end
  end
end
