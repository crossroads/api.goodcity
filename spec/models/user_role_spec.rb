require 'rails_helper'

RSpec.describe UserRole, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to :role }
    it { is_expected.to belong_to :user }
  end

  describe 'Database columns' do
    it { is_expected.to have_db_column(:user_id).of_type(:integer) }
    it { is_expected.to have_db_column(:role_id).of_type(:integer) }
  end
end
