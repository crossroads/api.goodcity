require 'rails_helper'

RSpec.describe AccessPass, type: :model do
  describe 'Association' do
    it { is_expected.to belong_to :printer }
    it { is_expected.to belong_to :generated_by }
    it { is_expected.to have_many :access_passes_roles }
    it { is_expected.to have_many :roles }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:access_key).of_type(:integer)}
    it{ is_expected.to have_db_column(:generated_by_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:printer_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:generated_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:access_expires_at).of_type(:datetime)}
  end

  describe ".refresh_pass" do
    it "would reset access-key" do
      access_pass = create :access_pass
      access_key = access_pass.access_key

      expect{
        access_pass.refresh_pass
      }.to change(access_pass, :access_key)
    end
  end

  describe ".valid_pass?" do
    it "should return boolean value based on access-key generation-time" do
      access_pass = create :access_pass
      expect(access_pass.valid_pass?).to be_truthy

      access_pass.update_column(:generated_at, 10.minutes.ago)
      expect(access_pass.valid_pass?).to be_falsy
    end
  end

  describe "#find_valid_pass" do
    it "should return valid non-expired pass" do
      access_pass = create :access_pass
      expect(AccessPass.find_valid_pass(access_pass.access_key)).to eq(access_pass)

      access_pass.update_column(:generated_at, 10.minutes.ago)
      expect(AccessPass.find_valid_pass(access_pass.access_key)).to be_falsy
    end
  end

  describe "access_expires_at" do
    it "should return valid non-expired pass" do
      access_pass = build :access_pass, access_expires_at: 2.days.from_now
      expect(access_pass.valid?).to be_truthy

      access_pass = build :access_pass, access_expires_at: 15.days.from_now
      expect(access_pass.valid?).to be_falsy
    end
  end
end
