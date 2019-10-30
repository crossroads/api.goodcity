require 'rails_helper'

RSpec.describe ComputerAccessory, type: :model do

  describe "Associations" do
    it { is_expected.to belong_to :country }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:brand).of_type(:string)}
    it{ is_expected.to have_db_column(:model).of_type(:string)}
    it{ is_expected.to have_db_column(:serial_num).of_type(:string)}
    it{ is_expected.to have_db_column(:country_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:size).of_type(:string)}
    it{ is_expected.to have_db_column(:interface).of_type(:string)}
    it{ is_expected.to have_db_column(:comp_voltage).of_type(:string)}
    it{ is_expected.to have_db_column(:comp_test_status).of_type(:string)}
    it{ is_expected.to have_db_column(:updated_by_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:stockit_id).of_type(:integer)}
  end

  describe "before_save" do
    it "should convert brand to lowercase" do
      computer_accessory = build :computer_accessory, brand: "DeLL"
      allow(Stockit::ItemDetailSync).to receive(:create).with(computer_accessory).and_return({"status"=>201, "computer_id"=> 12})
      computer_accessory.save
      expect(computer_accessory.brand).to eq("dell")
    end

    it "should set updated_by if changes done" do
      user = create(:user, :reviewer)
      User.current_user = user
      computer_accessory = build :computer_accessory, brand: "DeLL"
      allow(Stockit::ItemDetailSync).to receive(:create).with(computer_accessory).and_return({"status"=>201, "computer_accessory_id"=> 12})
      expect {
        computer_accessory.save
      }.to change(ComputerAccessory, :count).by(1)
      expect(computer_accessory.updated_by_id).to eq(user.id)
    end
  end
end
