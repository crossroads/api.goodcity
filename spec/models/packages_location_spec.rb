require 'rails_helper'

RSpec.describe PackagesLocation, type: :model do
  before { User.current_user = create(:user) }

  describe "Associations" do
    it { is_expected.to belong_to :location }
    it { is_expected.to belong_to :package }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:package_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:location_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:quantity).of_type(:integer)}
  end

  describe 'Validations' do
    it 'validates quantity' do
      is_expected.to_not allow_value(-1).for(:quantity)
      is_expected.to allow_value(rand(1..99999999)).for(:quantity)
    end
  end

  describe "Live updates" do
    let(:push_service) { PushService.new }
    let!(:package) { create :package, :package_with_locations, received_quantity: 1 }
    let!(:package_from_donor) { create :package, :with_item, :package_with_locations, received_quantity: 1 }
    let(:package_location) { package.packages_locations.first }
    let(:package_location_from_donor) { package_from_donor.packages_locations.first }

    before(:each) do
      allow(PushService).to receive(:new).and_return(push_service)
    end

    it "should call push_changes upon change" do
      expect(package_location).to receive(:push_changes)
      package_location.quantity = 2
      package_location.save
    end

    it "should send changes to the stock channel" do
      expect(push_service).to receive(:send_update_store) do |channels, data|
        expect(channels.length).to eq(1)
        expect(channels).to eq([ Channel::STOCK_CHANNEL ])
      end
      package_location.quantity = 2
      package_location.save
    end

    it "should send changes to the staff if the package has an item (indicates it's from a donor)" do
      expect(push_service).to receive(:send_update_store) do |channels, data|
        expect(channels.length).to eq(2)
        expect(channels).to eq([ Channel::STOCK_CHANNEL, Channel::STAFF_CHANNEL ])
      end
      package_location_from_donor.quantity = 2
      package_location_from_donor.save
    end
  end
end
