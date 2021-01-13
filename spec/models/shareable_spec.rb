require 'rails_helper'

RSpec.describe Shareable, type: :model do
  let(:offer) { create(:offer) }
  let(:user) { create(:user) }

  describe 'Database columns' do
    it { is_expected.to have_db_column(:public_uid).of_type(:string) }
    it { is_expected.to have_db_column(:notes).of_type(:text) }
    it { is_expected.to have_db_column(:notes_zh_tw).of_type(:text) }
    it { is_expected.to have_db_column(:resource_id).of_type(:integer) }
    it { is_expected.to have_db_column(:resource_type).of_type(:string) }
    it { is_expected.to have_db_column(:allow_listing).of_type(:boolean) }
    it { is_expected.to have_db_column(:created_by_id).of_type(:integer) }
    it { is_expected.to have_db_column(:expires_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime) }
  end

  describe 'Associations' do
    it { is_expected.to belong_to :created_by }
    it { is_expected.to belong_to :resource }
  end

  describe 'Lifecycle' do
    describe 'on creation' do
      it 'is auto-assigned a public_uid' do
        shareable = Shareable.create(resource: offer, created_by: user)
        expect(shareable.public_uid).not_to be_nil
      end
    end
  end
end
