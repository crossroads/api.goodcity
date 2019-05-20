require "rails_helper"

RSpec.describe Api::V1::OrganisationsUsersController, type: :controller do
  let(:supervisor) { create(:user_with_token, :with_can_manage_organisations_users_permission, role_name: 'Supervisor') }
  before { generate_and_set_token(supervisor) }
  let(:organisation) { create :organisation }
  let(:new_organisation) { create :organisation }
  let!(:charity_role) { create :charity_role }
  let(:user_attributes) do
    FactoryBot.attributes_for(:user, :with_email)
  end

  let(:user) { create :user}
  let(:organisations_user) { create :organisations_user , organisation_id: "#{new_organisation.id}", user_id: "#{supervisor.id}"}
  let(:organisations_user_without_role) { create :organisations_user , organisation_id: "#{new_organisation.id}", user_id: "#{user.id}"}

  let(:update_user_attributes) do
    FactoryBot.attributes_for(:user, :with_email, last_name: "Cooper")
  end

  let(:organisations_user_params) do
    FactoryBot.attributes_for(:organisations_user, organisation_id: "#{organisation.id}", user_attributes: user_attributes)
  end
  let(:new_organisations_user_params) do
    FactoryBot.attributes_for(:organisations_user, organisation_id: "#{organisation.id}", user_attributes: user_attributes)
  end

  let(:update_organisations_user_params) do
    FactoryBot.attributes_for(:organisations_user, organisation_id: "#{new_organisation.id}", user_attributes: update_user_attributes, id: "#{organisations_user_without_role.id}")
  end

  let(:subject) { JSON.parse(response.body) }

  describe "POST organisations_user/1" do

    it "creates new organisations user", :show_in_doc do
      set_browse_app_header
      expect {
        post :create, format: :json, organisations_user: organisations_user_params
      }.to change(OrganisationsUser, :count).by(1)
      expect(response.status).to eq(201)
    end

    it "sends error if new organisations_user is with invalid mobile number", :show_in_doc do
      organisations_user_params[:user_attributes][:mobile] = "23535"
      expect {
        post :create, format: :json, organisations_user: organisations_user_params
      }.to change(OrganisationsUser, :count).by(0)
      expect(response.status).to eq(422)
      expect(subject["errors"]).to eq("Mobile is invalid")
    end

    it "sends error if new organisations_user is with invalid email id", :show_in_doc do
      organisations_user_params[:user_attributes][:email] = "abc"
      expect {
        post :create, format: :json, organisations_user: organisations_user_params
      }.to change(OrganisationsUser, :count).by(0)
      expect(response.status).to eq(422)
      expect(subject["errors"]).to eq("Email is invalid")
    end

    it "creates new organisations_user record  if user with mobile number exists in db and its not assigned to same organisation" do
      organisations_user = create :organisations_user
      organisations_user_params[:user_attributes][:mobile] = organisations_user.user.mobile
      expect {
        post :create, format: :json, organisations_user: organisations_user_params
      }.to change(OrganisationsUser, :count).by(1)
      expect(response.status).to eq(201)
    end

    it "do not create organisation_user and sends error if mobile number already exists in organisation", :show_in_doc do
      organisations_user = create :organisations_user
      new_organisations_user_params[:organisation_id] = organisations_user.organisation_id.to_s
      new_organisations_user_params[:user_attributes][:mobile] = organisations_user.user.mobile
      expect {
        post :create, format: :json, organisations_user: new_organisations_user_params
      }.to change(OrganisationsUser, :count).by(0)
      expect(response.status).to eq(422)
      expect(subject["errors"]).to eq("User already exists in this organisation")
    end
  end

  describe "PUT organisations_user/1" do
    it "update user_attributes of organisations_user ", :show_in_doc do
      organisations_user_id = update_organisations_user_params[:id]
      put :update, id: organisations_user_id, organisations_user: update_organisations_user_params
      organisations_user = OrganisationsUser.find_by_id(organisations_user_id)
      expect(organisations_user.user.last_name).to eq(update_user_attributes[:last_name])
    end

    it "update position of organisations_user ", :show_in_doc do
      organisations_user_id = update_organisations_user_params[:id]
      update_organisations_user_params[:position] = "Admin"
      put :update, id: organisations_user_id, organisations_user: update_organisations_user_params
      organisations_user = OrganisationsUser.find_by_id(organisations_user_id)
      expect(organisations_user.position).to eq("Admin")
    end

    it "it adds charity_role to organisations_user" do
      update_organisations_user_params
      organisations_user_id = update_organisations_user_params[:id]
      put :update, id: organisations_user_id, organisations_user: update_organisations_user_params
      organisations_user = OrganisationsUser.find_by_id(organisations_user_id)
      expect(organisations_user.user.roles.pluck(:name)).to include("Charity")
    end
  end
end


