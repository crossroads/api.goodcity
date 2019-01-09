require 'rails_helper'

#testing package_filtering concern
describe Package do
  # testing dispatched packages
  context 'in_stock packages' do
    before(:each) do
      create :package, inventory_number: "111000", state: 'received', quantity: 1
      create :package, inventory_number: "111001", state: 'received', allow_web_publish: true, quantity: 1
      create :package, inventory_number: "111002", state: 'received', quantity: 0
      create(:package, :with_images, inventory_number: "111003", state: 'received', quantity: 1)
      create(:package, :with_images, inventory_number: "111005", allow_web_publish: true, state: 'received', quantity: 1)
    end

    it 'Should not filter out anything if no explicit arguments are provided/selected' do
      expect(Package.count).to eq(5)
      expect(Package.where("inventory_number ILIKE '%111%'").count).to eq(5)
      expect(Package.where("inventory_number ILIKE '%111%'").filter().count).to eq(5)
    end

    it 'Should return in stock items where state is received and quantity > 0' do
      expect(Package.count).to eq(5)
      expect(Package.where("inventory_number ILIKE '%111%'").count).to eq(5)
      expect(Package.where("inventory_number ILIKE '%111%'").filter(states: ['in_stock']).count).to eq(4)
    end

    it 'should return in_stock items with/without published status' do
      expect(Package.count).to eq(5)
      expect(Package.where("inventory_number ILIKE '%111%'").filter(states: ['in_stock', 'published_and_private']).count).to eq(4)
    end

    it 'should return in stock items with published status' do
      expect(Package.count).to eq(5)
      expect(Package.where("inventory_number ILIKE '%111%'").filter(states: ['in_stock', 'published']).count).to eq(2)
    end

    it 'should return in stock items with un-published status' do
      expect(Package.count).to eq(5)
      expect(Package.where("inventory_number ILIKE '%111%'").filter(states: ['in_stock', 'private']).count).to eq(2)
    end

     it 'should return in_stock items with/without images' do
      expect(Package.count).to eq(5)
      expect(Package.where("inventory_number ILIKE '%111%'").filter(states: ['in_stock', 'published_and_private', 'with_and_without_images']).count).to eq(4)
    end

    it 'should return in stock items with images' do
      expect(Package.count).to eq(5)
      expect(Package.where("inventory_number ILIKE '%111%'").filter(states: ['in_stock', 'published', 'has_images']).count).to eq(1)
    end

    it 'should return in stock items without images' do
      expect(Package.count).to eq(5)
      expect(Package.where("inventory_number ILIKE '%111%'").filter(states: ['in_stock', 'private', 'no_images']).count).to eq(1)
    end
  end

  # testing designated packages
  context 'designated packages' do
    before(:each) do
      @order_package = create(:orders_package, :with_state_designated, quantity: 1)
      create(:package, :with_images, inventory_number: "111003", state: 'received', quantity: 1)
      create(:package, :with_images, inventory_number: "111005", allow_web_publish: true, state: 'received', quantity: 1)
    end

    it 'Should not filter out anything if no explicit arguments are provided/selected' do
      expect(Package.count).to eq(3)
      expect(Package.where("inventory_number ILIKE '%111%'").count).to eq(2)
      expect(Package.where("inventory_number ILIKE '%111%'").filter().count).to eq(2)
    end

    it 'should filter out only designated packages' do
      package_inventory = @order_package.package.update(inventory_number: '111006')
      expect(Package.where("inventory_number ILIKE '%111%'").filter(states: ['designated']).count).to eq(1)
    end
  end

  # testing dispatched packages
  context 'dispatched packages' do
    before(:each) do
      @order_package = create(:orders_package, :with_state_dispatched, quantity: 1)
      create(:package, :with_images, inventory_number: "111003", state: 'received', quantity: 1)
      create(:package, :with_images, inventory_number: "111005", allow_web_publish: true, state: 'received', quantity: 1)
    end

    it 'Should not filter out anything if no explicit arguments are provided/selected' do
      expect(Package.count).to eq(3)
      expect(Package.where("inventory_number ILIKE '%111%'").count).to eq(2)
      expect(Package.where("inventory_number ILIKE '%111%'").filter().count).to eq(2)
    end

    it 'should filter out only dispatched packages' do
      package_inventory = @order_package.package.update(inventory_number: '111007')
      expect(Package.where("inventory_number ILIKE '%111%'").filter(states: ['dispatched']).count).to eq(1)
    end
  end

  context 'filter based on location' do
    before(:each) do
      @package_with_location = create(:package, :package_with_locations, inventory_number: "111003", state: 'received', quantity: 1)
      create(:package, :with_images, inventory_number: "111005", allow_web_publish: true, state: 'received', quantity: 1)
      create(:package, :with_images, inventory_number: "111006", allow_web_publish: true, state: 'received', quantity: 1)
    end

    it 'Should not filter out anything if no explicit arguments are provided/selected' do
      expect(Package.count).to eq(3)
      expect(Package.where("inventory_number ILIKE '%111%'").count).to eq(3)
      expect(Package.where("inventory_number ILIKE '%111%'").filter().count).to eq(3)
    end

    # it 'should filter out item based on location' do
    #   expect(Package.count).to eq(3)
    #   pkg_location_name = @package_with_location.locations.pluck(:building, :area).first.join('-')
    #   expect(Package.where("inventory_number ILIKE '%111%'")
    #     .filter(states: ['in_stock'], location: pkg_location_name).count)
    #     .to eq(1)
    # end
  end
end
