require 'rails_helper'

describe Package do
  before { User.current_user = create(:user) }

  # testing dispatched packages
  context 'in_stock packages' do
    before(:each) do
      create(:package, :with_inventory_record, state: 'received', received_quantity: 1)
      create(:package, :with_inventory_record, state: 'received', allow_web_publish: true, received_quantity: 1)
      create(:package, :with_inventory_record, :with_images, state: 'received', received_quantity: 1)
      create(:package, :with_inventory_record, :with_images, allow_web_publish: true, state: 'received', received_quantity: 1)
      create(:package, :dispatched, :with_inventory_record, state: 'received', received_quantity: 1) # Dispatched
    end

    subject { Package.apply_filter('state' => state).count }

    it 'does not filter out anything if no explicit arguments are provided' do
      expect(Package.count).to eq(5)
      expect(Package.count).to eq(5)
      expect(Package.apply_filter.count).to eq(5)
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
      package = create(:package, :with_inventory_record, :with_images, allow_web_publish: true, state: 'received', received_quantity: 1)
      order = create(:order)
      create(:package, :with_inventory_record, :with_images, state: 'received', received_quantity: 1)
      create(:orders_package, :with_inventory_record, :with_state_designated, quantity: 1, order_id: order.id, package_id: package.id)
    end

    it 'filters out only designated packages' do
      expect(Package.apply_filter.count).to eq(2)
      expect(Package.apply_filter('state' => 'designated').count).to eq(1)
    end
  end

  context 'packages with associated package-types' do
    before(:each) do
      parent_package_type = create :package_type, code: "VCL"
      child_package_type = parent_package_type.child_package_types.first

      @parent_package = create(:package, :with_inventory_record, package_type_id: parent_package_type.id)
      @child_package = create(:package, :with_inventory_record, package_type_id: child_package_type.id)
      @other_package = create(:package, :with_inventory_record, package_type_id: (create :package_type, code: "HPW").id)
    end

    it 'filters out only associated package-types packages' do
      expect(Package.apply_filter.count).to eq(3)

      packages = Package.apply_filter('associated_package_types_for' => ["VCL"])
      expect(packages.count).to eq(2)
      expect(packages).to match_array([@parent_package, @child_package])
      expect(packages).to_not include(@other_package)
    end
  end

  context 'dispatched packages' do
    before(:each) do
      package = create(:package, :with_inventory_record, :with_images, allow_web_publish: true, state: 'received', received_quantity: 1)
      order = create(:order)
      create(:package, :with_inventory_record, :with_images, state: 'received', received_quantity: 1)
      create(:orders_package, :with_inventory_record, :with_state_dispatched, quantity: 1, order_id: order.id, package_id: package.id)
    end

    it 'filters out only dispatched packages' do
      expect(Package.apply_filter.count).to eq(2)
      expect(Package.apply_filter('state' => 'dispatched').count).to eq(1)
    end
  end

  describe "loss actions on packages" do
    context 'processed packages' do
      before(:each) do
        package = create(:package, :with_inventory_record, :with_images, allow_web_publish: true, state: 'received', received_quantity: 10)
        create(:packages_inventory, :process, location: package.locations.first, package: package)
        create(:packages_inventory, :process, location: package.locations.first, package: package)
        package1 = create(:package, :with_inventory_record, :with_images, allow_web_publish: true, state: 'received', received_quantity: 10)
        create(:packages_inventory, :unprocess, location: package1.locations.first, package: package1)
      end


      it 'filters out only processed packages' do
        expect(Package.apply_filter('state' => 'process').count).to eq(1)
      end
    end

    context 'lost packages' do
      before(:each) do
        package = create(:package, :with_inventory_record, :with_images, allow_web_publish: true, state: 'received', received_quantity: 10)
        create(:packages_inventory, :loss, location: package.locations.first, package: package)
        create(:packages_inventory, :loss, location: package.locations.first, package: package)
        package1 = create(:package, :with_inventory_record, :with_images, allow_web_publish: true, state: 'received', received_quantity: 10)
        create(:packages_inventory, :gain, location: package1.locations.first, package: package1)
      end


      it 'filters out only lost packages' do
        expect(Package.apply_filter('state' => 'loss').count).to eq(1)
      end
    end

    context 'packed packages' do
      before(:each) do
        package = create(:package, :with_inventory_record, :with_images, allow_web_publish: true, state: 'received', received_quantity: 10)
        create(:packages_inventory, :pack, location: package.locations.first, package: package)
        create(:packages_inventory, :pack, location: package.locations.first, package: package)
        package1 = create(:package, :with_inventory_record, :with_images, allow_web_publish: true, state: 'received', received_quantity: 10)
        create(:packages_inventory, :unpack, location: package1.locations.first, package: package1)
      end


      it 'filters out only packed packages' do
        expect(Package.apply_filter('state' => 'pack').count).to eq(1)
      end
    end

    context 'trashed packages' do
      before(:each) do
        package = create(:package, :with_inventory_record, :with_images, allow_web_publish: true, state: 'received', received_quantity: 10)
        create(:packages_inventory, :trash, location: package.locations.first, package: package)
        create(:packages_inventory, :trash, location: package.locations.first, package: package)
        package1 = create(:package, :with_inventory_record, :with_images, allow_web_publish: true, state: 'received', received_quantity: 10)
        create(:packages_inventory, :untrash, location: package1.locations.first, package: package1)
      end


      it 'filters out only trashed packages' do
        expect(Package.apply_filter('state' => 'trash').count).to eq(1)
      end
    end

    context 'recycled packages' do
      before(:each) do
        package = create(:package, :with_inventory_record, :with_images, allow_web_publish: true, state: 'received', received_quantity: 10)
        create(:packages_inventory, :recycle, location: package.locations.first, package: package)
        create(:packages_inventory, :recycle, location: package.locations.first, package: package)
        package1 = create(:package, :with_inventory_record, :with_images, allow_web_publish: true, state: 'received', received_quantity: 10)
        create(:packages_inventory, :preserve, location: package1.locations.first, package: package1)
      end


      it 'filters out only recyled packages' do
        expect(Package.apply_filter('state' => 'recycle').count).to eq(1)
      end
    end
  end

  context 'filters based on location' do
    let(:location_a) { create :location, area: 'area1' }
    let(:location_b) { create :location, area: 'area2' }

    before(:each) do
      initialize_inventory(
        create(:package, :with_inventory_number, :with_images, allow_web_publish: true, state: 'received', received_quantity: 1),
        create(:package, :with_inventory_number, :with_images, allow_web_publish: true, state: 'received', received_quantity: 1),
        location: location_a
      )
      initialize_inventory(
        create(:package, :with_inventory_number, :with_images, allow_web_publish: true, state: 'received', received_quantity: 1),
        location: location_b
      )
    end

    it 'filters out item based on location' do
      pkg_location_name = "#{location_b.building}-#{location_b.area}"
      expect(Package.apply_filter.count).to eq(3)
      expect(Package.apply_filter('location' => pkg_location_name).count).to eq(1)
    end
  end

  context 'filters based on location_id (the move-stock helper, CR-291)' do
    # Two locations with the same building and area: the name filter can only ever reach the first (API-72).
    let!(:first_twin) { Location.create!(building: 'ZZ', area: 'Twin') }
    let!(:second_twin) { Location.create!(building: 'ZZ', area: 'Twin') }
    let(:elsewhere) { create :location, area: 'area3' }
    let!(:at_first) { create(:package, :with_inventory_number, state: 'received', received_quantity: 2) }
    let!(:at_second) { create(:package, :with_inventory_number, state: 'received', received_quantity: 3) }
    let!(:at_both) { create(:package, :with_inventory_number, state: 'received', received_quantity: 4) }
    let!(:not_here) { create(:package, :with_inventory_number, state: 'received', received_quantity: 1) }

    before(:each) do
      initialize_inventory(at_first, location: first_twin)
      initialize_inventory(at_second, at_both, location: second_twin)
      initialize_inventory(not_here, location: elsewhere)
      # at_both also has 1 at first_twin: a package at two places is listed for each of them.
      Package::Operations.move(1, at_both, from: second_twin.id, to: first_twin.id)
    end

    it 'lists exactly the packages with a packages_locations row at that location id' do
      expect(Package.apply_filter('location_id' => second_twin.id.to_s)).to match_array([at_second, at_both])
      expect(Package.apply_filter('location_id' => first_twin.id)).to match_array([at_first, at_both])
    end

    it 'reaches the second of two same-named locations, which the name filter cannot (API-72)' do
      expect(Package.apply_filter('location' => 'ZZ-Twin')).to match_array([at_first, at_both])
      expect(Package.apply_filter('location_id' => second_twin.id.to_s)).to match_array([at_second, at_both])
    end

    it 'lists a package once even when it is at that place and another' do
      expect(Package.apply_filter('location_id' => first_twin.id.to_s).to_a.count(at_both)).to eq(1)
    end

    it 'drops a package once its row there is gone (moved away)' do
      Package::Operations.move(3, at_second, from: second_twin.id, to: elsewhere.id)
      expect(Package.apply_filter('location_id' => second_twin.id.to_s)).to match_array([at_both])
    end

    it 'still leaves out packages with no inventory number, as the base filter always has' do
      no_number = create(:package, state: 'received', received_quantity: 1, inventory_number: nil)
      initialize_inventory(no_number, location: second_twin)
      expect(PackagesLocation.where(location_id: second_twin.id).pluck(:package_id)).to include(no_number.id)
      expect(Package.apply_filter('location_id' => second_twin.id.to_s)).not_to include(no_number)
    end

    it 'is empty for a location id with no stock or no such location' do
      empty = create :location, area: 'area4'
      expect(Package.apply_filter('location_id' => empty.id.to_s)).to be_empty
      expect(Package.apply_filter('location_id' => (Location.maximum(:id) + 1000).to_s)).to be_empty
    end

    it 'combines with the other filters' do
      expect(Package.apply_filter('location_id' => second_twin.id.to_s, 'state' => 'in_stock')).to match_array([at_second, at_both])
      expect(Package.apply_filter('location_id' => second_twin.id.to_s, 'location' => 'ZZ-Twin')).to match_array([at_both])
    end

    it 'leaves the SQL of every legacy call unchanged when location_id is absent or nil' do
      legacy = ->(opts) {
        # The pre-CR-291 apply_filter for these options, verbatim.
        q = Package.where.not(inventory_number: nil)
        q = q.where_states(%w[in_stock]) if opts['state'] == 'in_stock'
        q = q.filter_by_location(opts['location']) if opts['location'].present?
        q.distinct.to_sql
      }
      [{}, { 'location' => 'ZZ-Twin' }, { 'state' => 'in_stock' }, { 'state' => 'in_stock', 'location' => 'ZZ-Twin' }].each do |opts|
        expect(Package.apply_filter(opts).to_sql).to eq(legacy.call(opts))
        expect(Package.apply_filter(opts.merge('location_id' => nil)).to_sql).to eq(legacy.call(opts))
      end
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

    context 'should find items by package-type code' do
      let!(:code) { create :package_type, code: "HPB" }
      let!(:pkg1) { create :package, package_type: code }
      let!(:pkg2) { create :package, package_type: code }
      let!(:pkg3) { create :package, package_type: create(:package_type, code: 'MDV') }
      let(:search_text) { 'HPB' }
      it do
        expect(subject.size).to eql(2)
        expect(subject.to_a).to include(pkg1)
        expect(subject.to_a).to include(pkg2)
      end
    end

    context "should find items by package-type name" do
      let!(:code) { create :package_type, name: "Bookshelf", code: "FSB" }
      let!(:pkg1) { create :package, package_type: code }
      let!(:pkg2) { create :package, package_type: code }
      let!(:pkg3) { create :package, package_type: create(:package_type, code: 'MDV') }
      let(:search_text) { "book" }
      it do
        expect(subject.size).to eql(2)
        expect(subject.to_a).to include(pkg1)
        expect(subject.to_a).to include(pkg2)
      end
    end
  end
end
