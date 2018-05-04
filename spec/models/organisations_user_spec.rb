require 'rails_helper'

RSpec.describe OrganisationsUser, type: :model do
  describe "Database columns" do
    it { is_expected.to have_db_column(:position).of_type(:string) }
    it { is_expected.to have_db_column(:user_id).of_type(:integer) }
    it { is_expected.to have_db_column(:organisation_id).of_type(:integer) }
  end

  describe "Associations" do
    it { is_expected.to belong_to :organisation }
    it { is_expected.to belong_to :user }
  end

  describe 'Callbacks' do
    it { is_expected.to callback(:send_welcome_msg).after(:create) }
    it { is_expected.to callback(:create_user_role).after(:create) }

    it "creates entry in UserRole table after creation OrganisationsUser" do
      organisation_user = build :organisations_user
      charity_role = create :charity_role
      expect{
        organisation_user.save
      }.to change(UserRole, :count).by(1)
    end
  end
end
