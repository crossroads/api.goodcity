require 'rails_helper'

RSpec.describe Electrical, type: :model do

  describe "Associations" do
    it { is_expected.to belong_to :country }
    it {is_expected.to belong_to(:voltage).class_name("Lookup")}
    it {is_expected.to belong_to(:frequency).class_name("Lookup")}
    it {is_expected.to belong_to(:test_status).class_name("Lookup")}
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:brand).of_type(:string)}
    it{ is_expected.to have_db_column(:model).of_type(:string)}
    it{ is_expected.to have_db_column(:serial_number).of_type(:string)}
    it{ is_expected.to have_db_column(:country_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:standard).of_type(:string)}
    it{ is_expected.to have_db_column(:voltage_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:frequency_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:power).of_type(:string)}
    it{ is_expected.to have_db_column(:system_or_region).of_type(:string)}
    it{ is_expected.to have_db_column(:test_status_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:tested_on).of_type(:date)}
    it{ is_expected.to have_db_column(:updated_by_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:stockit_id).of_type(:integer)}
  end

  describe "before_save" do
    it "should convert brand to lowercase" do
      electrical = build :electrical, brand: "PhiLips"
      expect {
        electrical.save
      }.to change(Electrical, :count).by(1)
      expect(electrical.brand).to eq("philips")
    end

    it "should set tested on date on test status change" do
      electrical = build :electrical
      expect {
        electrical.save
      }.to change(Electrical, :count).by(1)
      expect(electrical.tested_on).to_not be(nil)
    end

    it "should set updated_by if changes done" do
      user = create(:user, :reviewer)
      User.current_user = user
      electrical = build :electrical, brand: "DeLL"
      expect {
        electrical.save
      }.to change(Electrical, :count).by(1)
      expect(electrical.updated_by_id).to eq(user.id)
    end
  end
end
