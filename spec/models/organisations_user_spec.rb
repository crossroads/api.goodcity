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

  describe "validations" do
    it { is_expected.to validate_presence_of(:organisation_id) }
    it { is_expected.to validate_presence_of(:user_id) }
  end

end
