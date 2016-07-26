require "rails_helper"

RSpec.describe Holiday, type: :model do

  describe "Database columns" do
    it { is_expected.to have_db_column(:holiday).of_type(:datetime) }
    it { is_expected.to have_db_column(:year).of_type(:integer) }
  end

  context "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:holiday) }
    it { is_expected.to validate_uniqueness_of(:holiday) }
  end

  describe "scope" do
    describe ".within_days" do
      it "should return holidays in given range of days" do
        holiday = create :holiday
        expect(Holiday.within_days(10.days)).to include(holiday)
      end
    end
  end

  describe 'callback' do
    describe 'set_year' do
      it "assigns year to record" do
        future_date = Time.now + 2.years
        holiday = create :holiday, holiday: future_date
        expect(holiday.year).to eq(future_date.year)
      end
    end
  end
end
