require 'rails_helper'

RSpec.describe Request, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to :order }
    it { is_expected.to belong_to :package_type }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:quantity).of_type(:integer)}
    it{ is_expected.to have_db_column(:description).of_type(:text)}
    it{ is_expected.to have_db_column(:order_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:package_type_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:created_by_id).of_type(:integer)}
  end

  describe "validations" do
    it { is_expected.to_not allow_value(0).for(:quantity) }
    it { is_expected.to allow_value(1).for(:quantity) }
  end
end
