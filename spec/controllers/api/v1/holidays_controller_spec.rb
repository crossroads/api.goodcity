require "rails_helper"

RSpec.describe Api::V1::HolidaysController, type: :controller do

  let(:holiday)  { create :holiday }
  let!(:holiday_1) { create(:holiday) }
  let!(:holiday_2) { create(:holiday, holiday: Time.zone.now + 7.days) }
  let(:reviewer) { create(:user, :reviewer) }

  before { generate_and_set_token(reviewer) }

  describe "GET available_dates" do

    it "returns 200" do
      get :available_dates
      expect(response.status).to eq(200)
    end

    it "return serialized available_dates", :show_in_doc do
      get :available_dates
      body = JSON.parse(response.body)
      expect(body.length).to eq(NEXT_AVAILABLE_DAYS_COUNT)
    end

    it "return serialized available_dates within given range", :show_in_doc do
      get :available_dates, schedule_days: 6, start_from: 2
      body = JSON.parse(response.body)
      expect(body.length).to eq(6)
      expect(body).to_not include(JSON.parse(holiday_1.holiday.to_json))
    end
  end

  describe 'DELETE holiday/1' do
    it "deletes holiday record", :show_in_doc do
      delete :destroy, id: holiday.id
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body).to eq( {} )
    end
  end

  describe "POST holiday/1" do
    it "returns 201", :show_in_doc do
      post :create, holiday: attributes_for(:holiday)
      expect(response.status).to eq(201)
    end
  end

  describe "PUT holiday/1" do
    it "admin can update", :show_in_doc do
      extra_params = { name: "Test holiday" }
      put :update, id: holiday.id, holiday: holiday.attributes.merge(extra_params)
      expect(response.status).to eq(200)
      expect(holiday.reload.name).to eq("Test holiday")
    end
  end

end
