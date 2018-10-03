require 'rails_helper'

RSpec.describe Beneficiary, type: :model do

  describe 'Database Columns' do
    it { is_expected.to have_db_column(:identity_type_id).of_type(:integer) }
    it { is_expected.to have_db_column(:identity_number).of_type(:string) }
    it { is_expected.to have_db_column(:title).of_type(:string) }
    it { is_expected.to have_db_column(:first_name).of_type(:string) }
    it { is_expected.to have_db_column(:last_name).of_type(:string) }
    it { is_expected.to have_db_column(:phone_number).of_type(:string) }
    it { is_expected.to have_db_column(:created_by_id).of_type(:integer) }
  end

  describe "Associations" do
    it { is_expected.to belong_to :identity_type }
    it { is_expected.to belong_to :created_by }
  end
  
end
