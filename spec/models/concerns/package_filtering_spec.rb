require 'rails_helper'

describe Package do
  before { User.current_user = create(:user) }
  
  # testing dispatched packages
  context 'in_stock packages' do
    before(:each) do
      create(:package, state: 'received', quantity: 1)
      create(:package, state: 'received', allow_web_publish: true, quantity: 1)
      create(:package, state: 'received', quantity: 0)
      create(:package, :with_images, state: 'received', quantity: 1)
      create(:package, :with_images, allow_web_publish: true, state: 'received', quantity: 1)
    end

    subject { Package.filter('state' => state).count }

    it 'does not filter out anything if no explicit arguments are provided' do
      expect(Package.count).to eq(5)
      expect(Package.count).to eq(5)
      expect(Package.filter.count).to eq(5)
    end

    context 'returns in stock items where state is received and quantity > 0' do
      let(:state) { 'in_stock' }
      it { expect(subject).to eq(4) }
    end

    context 'returns in_stock items with/without published status' do
      let(:state) { 'in_stock,published_and_private' }
      it { expect(subject).to eq(4) }
    end

    context 'returns in stock items with published status' do
      let(:state) { 'in_stock,published' }
      it { expect(subject).to eq(2) }
    end

    context 'returns in stock items with un-published status' do
      let(:state) { 'in_stock,private' }
      it { expect(subject).to eq(2) }
    end

    context 'returns in_stock items with/without images' do
      let(:state) { 'in_stock,published_and_private,with_and_without_images' }
      it { expect(subject).to eq(4) }
    end

    context 'returns in stock items with images' do
      let(:state) { 'in_stock,published,has_images' }
      it { expect(subject).to eq(1) }
    end

    context 'returns in stock items without images' do
      let(:state) { 'in_stock,private,no_images' }
      it { expect(subject).to eq(1) }
    end
  end

  context 'designated packages' do
    before(:each) do
      create(:orders_package, :with_state_designated, quantity: 1)
      create(:package, :with_images, state: 'received', quantity: 1)
      create(:package, :with_images, allow_web_publish: true, state: 'received', quantity: 1)
    end
    it 'filters out only designated packages' do
      expect(Package.filter.count).to eq(3)
      expect(Package.filter('state' => 'designated').count).to eq(1)
    end
  end

  context 'dispatched packages' do
    before(:each) do
      create(:orders_package, :with_state_dispatched, quantity: 1)
      create(:package, :with_images, state: 'received', quantity: 1)
      create(:package, :with_images, allow_web_publish: true, state: 'received', quantity: 1)
    end
    it 'filters out only dispatched packages' do
      expect(Package.filter.count).to eq(3)
      expect(Package.filter('state' => 'dispatched').count).to eq(1)
    end
  end

  context 'filters based on location' do
    before(:each) do
      create(:package, :with_images, allow_web_publish: true, state: 'received', quantity: 1)
      create(:package, :with_images, allow_web_publish: true, state: 'received', quantity: 1)
    end
    let(:package_with_location) { create(:package, :package_with_locations, state: 'received', quantity: 1) }

    it 'filters out item based on location' do
      pkg_location_name = package_with_location.locations.pluck(:building, :area).first.join('-')
      expect(Package.filter.count).to eq(3)
      expect(Package.filter('location' => pkg_location_name).count).to eq(1)
    end
  end

  context "search" do
    let(:item_id) { nil }
    let(:state) { [] }
    let(:options) { {search_text: search_text, item_id: item_id, state: state} }
    
    subject { Package.search(options) }

    context 'should find items by inventory number' do
      let!(:pkg1) { create :package, received_quantity: 1, inventory_number: "456222" }
      let!(:pkg2) { create :package, received_quantity: 1, inventory_number: "111111" }
      let!(:pkg3) { create :package, received_quantity: 2, inventory_number: "456333" }
      let(:search_text) { '456' }
      it do
        expect(subject.size).to eql(2)
        expect(subject.to_a).to include(pkg1)
        expect(subject.to_a).to include(pkg3)
      end
    end

    context 'should find items by notes' do
      let!(:pkg1) { create :package, received_quantity: 1, notes: "butter" }
      let!(:pkg2) { create :package, received_quantity: 2, notes: "butterfly" }
      let!(:pkg3) { create :package, received_quantity: 1, notes: "margarine" }
      let(:search_text) { 'UTter' }
      it do
        expect(subject.size).to eql(2)
        expect(subject.to_a).to include(pkg1)
        expect(subject.to_a).to include(pkg2)
      end
    end

    context 'should find items by notes' do
      let!(:pkg1) { create :package, received_quantity: 1, case_number: "CAS-123" }
      let!(:pkg2) { create :package, received_quantity: 2, case_number: "CAS-124" }
      let!(:pkg3) { create :package, received_quantity: 1, case_number: "CAS-666" }
      let(:search_text) { 'cas-12' }
      it do
        expect(subject.size).to eql(2)
        expect(subject.to_a).to include(pkg1)
        expect(subject.to_a).to include(pkg2)
      end
    end

    context 'should find items by designation_name' do
      let!(:pkg1) { create :package, received_quantity: 1, designation_name: "pepper" }
      let!(:pkg2) { create :package, received_quantity: 2, designation_name: "peppermint" }
      let!(:pkg3) { create :package, received_quantity: 1, designation_name: "garlic" }
      let(:search_text) { 'peP' }
      it do
        expect(subject.size).to eql(2)
        expect(subject.to_a).to include(pkg1)
        expect(subject.to_a).to include(pkg2)
      end
    end

  end
end
