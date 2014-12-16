require 'rails_helper'

RSpec.describe Api::V1::HolidaysController, type: :controller do

  let!(:holiday_1) { create(:holiday) }
  let!(:holiday_2) { create(:holiday, holiday: Time.zone.now + 7.days) }

  describe "GET available_dates" do

    it "returns 200" do
      get :available_dates
      expect(response.status).to eq(200)
    end

    it "return serialized available_dates", :show_in_doc do
      get :available_dates
      body = JSON.parse(response.body)
      expect( body.length ).to eq(10)
    end

    it "return serialized available_dates within given range", :show_in_doc do
      get :available_dates, schedule_days: 6
      body = JSON.parse(response.body)
      expect( body.length ).to eq(6)
      expect(body).to_not include(JSON.parse(holiday_1.holiday.to_json))
    end
  end

end
