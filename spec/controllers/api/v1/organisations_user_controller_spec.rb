require "rails_helper"

RSpec.describe Api::V1::OrganisationsUsersController, type: :controller do
  let(:supervisor) { create(:user_with_token, :supervisor) }
  before { generate_and_set_token(supervisor) }
  let(:organisation) { create :organisation }
  let!(:charity_permission) { create :charity_permission }
  let(:user_attributes) do
    FactoryGirl.attributes_for(:user, :with_email)
  end
  let(:organisations_user_params) do
    FactoryGirl.attributes_for(:organisations_user, organisation_id: "#{organisation.id}", user_attributes: user_attributes)
  end

  describe "POST organisations_user/1" do
    it "creates new organisations user", :show_in_doc do
      expect {
        post :create, format: :json, organisations_user: organisations_user_params
      }.to change(OrganisationsUser, :count).by(1)
      expect(response.status).to eq(201)
    end

    it "sends error if new organisations_user is with existing mobile number", :show_in_doc do
      organisations_user = create :organisations_user
      organisations_user_params[:user_attributes][:mobile] = organisations_user.user.mobile
      expect {
        post :create, format: :json, organisations_user: organisations_user_params
      }.to change(OrganisationsUser, :count).by(0)
      expect(response.status).to eq(422)
      expect(JSON.parse(response.body)["errors"]).to eq("Mobile has already been taken")
    end

    it "sends error if new organisations_user is with invalid mobile number", :show_in_doc do
      organisations_user_params[:user_attributes][:mobile] = "23535"
      expect {
        post :create, format: :json, organisations_user: organisations_user_params
      }.to change(OrganisationsUser, :count).by(0)
      expect(response.status).to eq(422)
      expect(JSON.parse(response.body)["errors"]).to eq("Mobile is invalid")
    end

    it "sends error if new organisations_user is with blank mobile number", :show_in_doc do
      organisations_user_params[:user_attributes][:mobile] = ""
      expect {
        post :create, format: :json, organisations_user: organisations_user_params
      }.to change(OrganisationsUser, :count).by(0)
      expect(response.status).to eq(422)
      expect(JSON.parse(response.body)["errors"]).to eq("Mobile can't be blank. Mobile is invalid")
    end

    it "sends error if new organisations_user is with invalid email id", :show_in_doc do
      organisations_user_params[:user_attributes][:email] = "abc"
      expect {
        post :create, format: :json, organisations_user: organisations_user_params
      }.to change(OrganisationsUser, :count).by(0)
      expect(response.status).to eq(422)
      expect(JSON.parse(response.body)["errors"]).to eq("User email is invalid")
    end
  end
end
