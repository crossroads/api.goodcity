require 'rails_helper'

RSpec.describe Permission, :type => :model do
  describe 'Associations' do
    it { is_expected.to have_many :role_permissions }
    it { is_expected.to have_many(:roles).through(:role_permissions) }
  end

  describe 'Database columns' do
    it { is_expected.to have_db_column(:name).of_type(:string) }
  end

  describe "Class Methods" do

    describe '.names' do
      it 'returns array of permission names associated with user' do
        user = create :user, :with_can_manage_offers_permission, role_name: 'Reviewer'
        expect(described_class.names(user.id)).to include('can_manage_offers')
        expect(described_class.names(user.id).count).to eq(1)
      end
    end
  end
end
