require 'rails_helper'

RSpec.describe OrdersPackage, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to :order }
    it { is_expected.to belong_to :package }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:package_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:order_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:quantity).of_type(:integer)}
    it{ is_expected.to have_db_column(:state).of_type(:string)}
    it{ is_expected.to have_db_column(:sent_on).of_type(:datetime)}
  end

  describe "update_state_to_designated" do
    it "set state='designated'"do
      @orders_package = create :orders_package, :with_state_requested
      @orders_package.update_state_to_designated
      expect(@orders_package.state).to match("designated")
    end
  end

  describe "update_quantity" do
    it "Updates orders_packages quantity" do
      @orders_package = create :orders_package, :with_state_requested
      @orders_package.update_quantity
  end

end
