require 'rails_helper'

RSpec.describe UserRole, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to :role }
    it { is_expected.to belong_to :user }
  end

  describe 'Database columns' do
    it { is_expected.to have_db_column(:user_id).of_type(:integer) }
    it { is_expected.to have_db_column(:role_id).of_type(:integer) }
    it { is_expected.to have_db_column(:expires_at).of_type(:datetime) }
  end

  describe 'expires_at time' do
    it "should set expires_at time as 8pm HKT" do
      user_role = create :user_role, expires_at: nil
      expires_at = DateTime.now.in_time_zone.days_since(10)

      user_role.expires_at = expires_at
      user_role.save

      expect(user_role.expires_at.hour).to eq(20)
      expect(user_role.expires_at.to_i).to eql(expires_at.change(hour: 20).to_i)
    end
  end
end
