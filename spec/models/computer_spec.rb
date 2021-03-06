require 'rails_helper'

RSpec.describe Computer, type: :model do

  describe "Associations" do
    it { is_expected.to belong_to :country }
    it { is_expected.to belong_to(:comp_test_status).class_name("Lookup") }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:brand).of_type(:string)}
    it{ is_expected.to have_db_column(:model).of_type(:string)}
    it{ is_expected.to have_db_column(:serial_num).of_type(:string)}
    it{ is_expected.to have_db_column(:country_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:size).of_type(:string)}
    it{ is_expected.to have_db_column(:cpu).of_type(:string)}
    it{ is_expected.to have_db_column(:ram).of_type(:string)}
    it{ is_expected.to have_db_column(:hdd).of_type(:string)}
    it{ is_expected.to have_db_column(:optical).of_type(:string)}
    it{ is_expected.to have_db_column(:video).of_type(:string)}
    it{ is_expected.to have_db_column(:sound).of_type(:string)}
    it{ is_expected.to have_db_column(:lan).of_type(:string)}
    it{ is_expected.to have_db_column(:wireless).of_type(:string)}
    it{ is_expected.to have_db_column(:usb).of_type(:string)}
    it{ is_expected.to have_db_column(:comp_voltage).of_type(:string)}
    it{ is_expected.to have_db_column(:comp_test_status_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:os).of_type(:string)}
    it{ is_expected.to have_db_column(:os_serial_num).of_type(:string)}
    it{ is_expected.to have_db_column(:ms_office_serial_num).of_type(:string)}
    it{ is_expected.to have_db_column(:mar_os_serial_num).of_type(:string)}
    it{ is_expected.to have_db_column(:mar_ms_office_serial_num).of_type(:string)}
    it{ is_expected.to have_db_column(:comp_voltage).of_type(:string)}
    it{ is_expected.to have_db_column(:updated_by_id).of_type(:integer)}
  end

  describe "before_save" do
    it "should convert brand to lowercase" do
      computer = build :computer, brand: "AppLE"
      expect {
        computer.save
      }.to change(Computer, :count).by(1)
      expect(computer.brand).to eq("apple")
    end

    it "should set updated_by if changes done" do
      user = create(:user, :reviewer)
      User.current_user = user
      computer = build :computer, brand: "DeLL"
      expect {
        computer.save
      }.to change(Computer, :count).by(1)
      expect(computer.updated_by_id).to eq(user.id)
    end
  end
end
