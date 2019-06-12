require 'rails_helper'

RSpec.describe Api::V1::GoodcitySettingsController, type: :controller do

  let(:supervisor_with_settings_permission)  { create(:user, :with_can_manage_settings, role_name: 'Supervisor') }
  let(:supervisor_without_settings_permission)  { create(:user, role_name: 'Supervisor') }
  let(:goodcity_setting) { create(:goodcity_setting) }
  let(:goodcity_setting_params) { FactoryBot.attributes_for(:goodcity_setting) }
  let(:parsed_body) { JSON.parse(response.body ) }

  describe "GET /goodicty_settings" do
    context "as a guest" do
      it "returns 200" do
        get :index
        expect(response.status).to eq(200)
      end
    end
  end

  describe "POST /goodicty_settings" do
    context "as a guest" do
      it "returns 401" do
        post :create, goodcity_setting: goodcity_setting_params
        expect(response.status).to eq(401)
      end
    end

    context "as a user without 'can_manage_settings' permission" do
      before { generate_and_set_token(supervisor_without_settings_permission) }
      it "returns 403" do
        post :create, goodcity_setting: goodcity_setting_params
        expect(response.status).to eq(403)
      end
    end

    context "as a user with 'can_manage_settings' permission" do
      before { generate_and_set_token(supervisor_with_settings_permission) }
      it "returns 200" do
        expect {
          post :create, goodcity_setting: goodcity_setting_params
        }.to change(GoodcitySetting, :count).by(1)
        expect(response.status).to eq(201)
      end
    end
  end

  describe "PUT /goodcity_setting/1" do
    before do
      goodcity_setting.save
    end

    context "as a guest" do
      it "returns 401" do
        put :update, id: goodcity_setting.id, goodcity_setting: goodcity_setting_params
        expect(response.status).to eq(401)
      end
    end

    context "as a user without 'can_manage_settings' permission" do
      before { generate_and_set_token(supervisor_without_settings_permission) }
      it "returns 403" do
        put :update, id: goodcity_setting.id, goodcity_setting: goodcity_setting_params
        expect(response.status).to eq(403)
      end
    end

    context "as a user with 'can_manage_settings' permission" do
      before { generate_and_set_token(supervisor_with_settings_permission) }
      it "returns 200" do
        expect {
          put :update, id: goodcity_setting.id, goodcity_setting: { id: goodcity_setting.id, value: 'steve is happy' }
        }.to change(GoodcitySetting, :count).by(0)
        expect(response.status).to eq(201)
        expect(GoodcitySetting.find(goodcity_setting.id).value).to eq('steve is happy');
      end
    end
  end

  describe "DELETE /goodcity_setting/1" do
    before do
      goodcity_setting.save
    end

    context "as a guest" do
      it "returns 401" do
        delete :destroy, id: goodcity_setting.id, goodcity_setting: goodcity_setting_params
        expect(response.status).to eq(401)
      end
    end

    context "as a user without 'can_manage_settings' permission" do
      before { generate_and_set_token(supervisor_without_settings_permission) }
      it "returns 403" do
        delete :destroy,  id: goodcity_setting.id, goodcity_setting: goodcity_setting_params
        expect(response.status).to eq(403)
      end
    end

    context "as a user with 'can_manage_settings' permission" do
      before { generate_and_set_token(supervisor_with_settings_permission) }
      it "returns 200" do
        expect {
          delete :destroy, id: goodcity_setting.id
        }.to change(GoodcitySetting, :count).by(-1)
        expect(response.status).to eq(200)
      end
    end
  end
end
