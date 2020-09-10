require 'rails_helper'

RSpec.describe UserRole, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to :role }
    it { is_expected.to belong_to :user }
  end

  describe 'Database columns' do
    it { is_expected.to have_db_column(:user_id).of_type(:integer) }
    it { is_expected.to have_db_column(:role_id).of_type(:integer) }
    it { is_expected.to have_db_column(:expiry_date).of_type(:datetime) }
  end

  describe 'expiry_date time' do
    it "should set expiry_date time as 8pm HKT" do
      user_role = create :user_role, expiry_date: nil
      expiry_date = DateTime.now.in_time_zone.days_since(10)

      user_role.expiry_date = expiry_date
      user_role.save

      expect(user_role.expiry_date.hour).to eq(20)
      expect(user_role.expiry_date.to_i).to eql(expiry_date.change(hour: 20).to_i)
    end
  end
end
