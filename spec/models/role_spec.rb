require 'rails_helper'

RSpec.describe Role, type: :model do
  describe 'Associations' do
    it { is_expected.to have_many :user_roles }
    it { is_expected.to have_many(:users).through(:user_roles) }
    it { is_expected.to have_many :role_permissions }
    it { is_expected.to have_many(:permissions).through(:role_permissions) }
  end

  describe 'Database columns' do
    it { is_expected.to have_db_column(:name).of_type(:string)}
  end

  describe "scope: allowed_roles" do
    let!(:reviewer_role) { create :reviewer_role }
    let!(:supervisor_role) { create :supervisor_role }

    it "return roles having level less than or equal to a given value" do
      allowed_roles = Role.allowed_roles(5)
      expect(allowed_roles.length).to eq(1)
      expect(allowed_roles).to include(reviewer_role)
      expect(allowed_roles).to_not include(supervisor_role)
    end
  end

end
