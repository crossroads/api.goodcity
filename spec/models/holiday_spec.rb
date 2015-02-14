require "rails_helper"

RSpec.describe Holiday, type: :model do
  describe "Database columns" do
    it { is_expected.to have_db_column(:holiday).of_type(:datetime) }
    it { is_expected.to have_db_column(:year).of_type(:integer) }
  end

  describe "scope" do
    describe ".within_days" do
      it "should return holidays in given range of days" do
        holiday = create :holiday
        expect(Holiday.within_days(10.days)).to include(holiday)
      end
    end
  end
end
