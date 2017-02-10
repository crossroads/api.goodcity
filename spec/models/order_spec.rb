require 'rails_helper'
require "rspec/mocks/standalone"

RSpec.describe Order, type: :model do

  describe "Associations" do
    it { is_expected.to belong_to :detail  }
    it { is_expected.to belong_to :stockit_activity }
    it { is_expected.to belong_to :country }
    it { is_expected.to belong_to :stockit_contact }
    it { is_expected.to belong_to :stockit_organisation }
    it { is_expected.to belong_to :organisation }
    it { is_expected.to belong_to(:created_by).class_name('User') }
    it { is_expected.to belong_to(:processed_by).class_name('User') }

    it { is_expected.to have_many :packages }
    it { is_expected.to have_and_belong_to_many :purposes }
    it { is_expected.to have_and_belong_to_many(:cart_packages).class_name('Package')}
    it { is_expected.to have_many :orders_packages }
    it { is_expected.to have_one :order_transport }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:status).of_type(:string)}
    it{ is_expected.to have_db_column(:code).of_type(:string)}
    it{ is_expected.to have_db_column(:detail_type).of_type(:string)}
    it{ is_expected.to have_db_column(:description).of_type(:text)}
    it{ is_expected.to have_db_column(:state).of_type(:string)}
    it{ is_expected.to have_db_column(:purpose_description).of_type(:text)}
    it{ is_expected.to have_db_column(:created_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:updated_at).of_type(:datetime)}
  end

  describe "Callbacks" do
    let(:order) { create(:order, :with_state_draft, :with_orders_packages) }

    it "Assigns GC Code" do
      expect(order.code).to include("GC-")
    end

    it "Updates orders_packages quantity" do
      order.orders_packages.each do |orders_package|
        expect(orders_package.reload.quantity).to eq(orders_package.package.quantity)
      end
    end
  end

  describe "Update OrdersPackages state" do
    let(:order) { create :order, :with_orders_packages  }
    it "Updates state to designated" do
      order.orders_packages.each do |orders_package|
        orders_package.update_state_to_designated
        expect(orders_package.state).to match("designated")
      end
    end
  end

end
