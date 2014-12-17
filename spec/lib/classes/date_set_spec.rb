require "rails_helper"

describe DateSet do

  let!(:holiday_1) { create(:holiday) }
  let!(:holiday_2) { create(:holiday, holiday: Time.zone.now + 15.days) }

  let!(:date_set) { DateSet.new }
  let!(:date_set_5) { DateSet.new(5, 2) }

  context "initialization" do
    it "days" do
      expect(
        date_set.instance_variable_get(:@days)
      ).to eql(NEXT_AVAILABLE_DAYS_COUNT)
    end

    it "holidays" do
      holidays_list = date_set.instance_variable_get(:@holidays)
      expect(holidays_list.count).to eq(2)
    end

    it "holidays" do
      holidays_list = date_set_5.instance_variable_get(:@holidays)
      expect(holidays_list.count).to eq(1)
      expect(holidays_list.first.to_date).to eq(holiday_1.holiday.to_date)
    end
  end

  context "available_dates" do
    it "should return next available dates" do
      next_dates = date_set.available_dates
      expect(next_dates.length).to eq(10)
      expect(next_dates.map(&:wday)).to_not include(0) # no sunday
      expect(next_dates.map(&:wday)).to_not include(1) # no monday
      expect(
        next_dates.map(&:to_date)
      ).to_not include(holiday_1.holiday.to_date) # no holidays

      expect(date_set_5.available_dates.length).to eq(5)
    end
  end

end
