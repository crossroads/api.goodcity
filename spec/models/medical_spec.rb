# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Medical, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to :country }
  end

  describe 'Database columns' do
    it { is_expected.to have_db_column(:serial_number) }
    it { is_expected.to have_db_column(:brand).of_type(:string) }
    it { is_expected.to have_db_column(:model).of_type(:string) }
    it { is_expected.to have_db_column(:country_id).of_type(:integer) }
    it { is_expected.to have_db_column(:expiry_date).of_type(:date) }
    it { is_expected.to have_db_column(:updated_by_id).of_type(:integer) }
    it { is_expected.to have_db_column(:stockit_id).of_type(:integer) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:expiry_date) }
  end

  describe 'before_save' do
    it 'should convert brand to lower case' do
      medical = build(:medical)
      name = medical.brand
      allow(Stockit::ItemDetailSync).to receive(:create)
        .with(medical)
        .and_return('status' => 201)
      expect { medical.save }.to change(Medical, :count).by(1)
      expect(medical.brand).to eq(name.downcase)
    end

    it 'should set updated_by if changes are done' do
      User.current_user = create(:user, :reviewer)
      medical = build(:medical)

      allow(Stockit::ItemDetailSync).to receive(:create)
        .with(medical)
        .and_return('status' => 201)
      expect { medical.save }.to change(Medical, :count).by(1)
      expect(medical.updated_by_id).to eq(User.current_user.id)
    end
  end
end
