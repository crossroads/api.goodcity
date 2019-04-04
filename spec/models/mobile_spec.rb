require 'rails_helper'

RSpec.describe Mobile, type: :model do
  describe '#Mobile' do
    [4,5,6,7,8,9].each do |n|
      it "is not a valid number if length of mobile is greater than 8" do
        mobile = Mobile.new("+852#{n}123456789")
        expect(mobile.valid?).to be_falsy
      end

      it "is not a valid number if length of mobile is greater than 8 and invalid mobile characters are there" do
        mobile = Mobile.new("+852#{n}sdaf93284")
        expect(mobile.valid?).to be_falsy
      end
    end

    [0,1,2,3].each do |n|
      it "is not valid if number is starting with #{n}" do
        mobile = Mobile.new("+852#{n}1234567")
        expect(mobile.valid?).to be_falsey
      end
    end

    [4,5,6,7,8,9].each do |n|
      it "is valid if number starts with #{n}" do
        mobile = Mobile.new("+852#{n}1234567")
        expect(mobile.valid?).to be_truthy
      end
    end
  end
end
