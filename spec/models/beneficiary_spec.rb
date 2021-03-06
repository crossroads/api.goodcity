require 'rails_helper'

RSpec.describe Beneficiary, type: :model do

  describe 'Database Columns' do
    it { is_expected.to have_db_column(:identity_type_id).of_type(:integer) }
    it { is_expected.to have_db_column(:identity_number).of_type(:string) }
    it { is_expected.to have_db_column(:title).of_type(:string) }
    it { is_expected.to have_db_column(:first_name).of_type(:string) }
    it { is_expected.to have_db_column(:last_name).of_type(:string) }
    it { is_expected.to have_db_column(:phone_number).of_type(:string) }
    it { is_expected.to have_db_column(:created_by_id).of_type(:integer) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:phone_number) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:identity_number) }
    it { is_expected.to validate_presence_of(:identity_type_id) }
    it { should validate_length_of(:first_name).is_at_most(50) }
    it { should validate_length_of(:last_name).is_at_most(50) }
  end

  describe "Associations" do
    it { is_expected.to belong_to :identity_type }
    it { is_expected.to belong_to :created_by }
  end

  describe "Lifecycle" do
    context "on destruction" do
      let(:order) { create :order }
      let(:beneficiary) { order.beneficiary }

      it "clears its own beneficiary_id from orders" do
        expect {
          beneficiary.destroy!
        }.to change {
          order.reload.beneficiary_id
        }.from(beneficiary.id).to(nil)
      end
    end
  end
end
