require 'rails_helper'

RSpec.describe Role, type: :model do
  describe 'Associations' do
    it { is_expected.to have_many :user_role_permissions }
    it { is_expected.to have_many(:users).through(:user_role_permissions) }
    it { is_expected.to have_many(:permissions).through(:user_role_permissions) }
  end

  describe 'Database columns' do
    it { is_expected.to have_db_column(:name).of_type(:string)}
  end
end
