require 'rails_helper'

RSpec.describe UserRolePermission, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to :user }
    it { is_expected.to belong_to :role }
    it { is_expected.to belong_to :permission }
  end

  describe 'Database columns' do
    it { is_expected.to have_db_column(:user_id).of_type(:integer) }
    it { is_expected.to have_db_column(:role_id).of_type(:integer) }
    it { is_expected.to have_db_column(:permission_id).of_type(:integer) }
  end
end
