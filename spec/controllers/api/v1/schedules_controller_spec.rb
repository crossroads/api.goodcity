require "rails_helper"

RSpec.describe Api::V1::SchedulesController, type: :controller do

  let(:user) { create(:user_with_token) }
  let(:schedule) { build(:schedule) }
  let(:schedule_params) { FactoryGirl.attributes_for(:schedule) }

  describe "GET availableTimeSlots" do
    before { generate_and_set_token(user) }
    it "returns 200", show_in_doc: true  do
      get :availableTimeSlots
      expect(response.status).to eq(200)
    end

    it "return serialized schedules", show_in_doc: true do
      post :create, schedule: schedule_params, format: :json
      body = JSON.parse(response.body)
      expect(response.status).to eq(201)
    end
  end
end
