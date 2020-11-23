require "rails_helper"

describe PackageSplitter do

  let(:package_splitter) { PackageSplitter.new(package, qty_to_split) }

  context "exception handling" do
    context "should fail if qty to split == qty" do
      let(:qty_to_split) { 1 }
      let(:package) { create(:package, :with_inventory_record, received_quantity: 1, inventory_number: "F00001") }
      it { expect { package_splitter.split! }.to raise_error(PackageSplitter::InvalidSplitQuantityError) }
    end

    context "should fail if qty to split > qty" do
      let(:qty_to_split) { 3 }
      let(:package) { create(:package, :with_inventory_record, received_quantity: 2, inventory_number: "F00001") }
      it { expect { package_splitter.split! }.to raise_error(PackageSplitter::InvalidSplitQuantityError) }
    end

    context "should succeed if qty to split < qty" do
      let(:qty_to_split) { 3 }
      let(:package) { create(:package, :with_inventory_record, received_quantity: 4, inventory_number: "F00001") }
      it { expect { package_splitter.split! }.not_to raise_error }
    end

    context "should fail if the package is not inventorized" do
      let(:qty_to_split) { 3 }
      let(:package) { create(:package, received_quantity: 2, inventory_number: "") }
      it { expect { package_splitter.split! }.to raise_error(Goodcity::NotInventorizedError) }
    end
  end

  context "split!" do
    let(:qty_to_split) { 2 }
    context "create 1 copies from qty 5 split (3,2)" do
      let(:inventory_number) { "F00001" }
      let(:inventory_number_q) { "#{inventory_number}Q" }
      let(:package) { create(:package, :with_inventory_record, received_quantity: 5, inventory_number: inventory_number) }
      it do
        expect{ package_splitter.split! }.to change(package.reload, :on_hand_quantity).from(5).to(3)
          .and change {package.received_quantity}.from(5).to(3)
        packages = Package.where("inventory_number LIKE ?", "#{inventory_number_q}%").order(:created_at)
        expect(packages.count).to eql(1)
        pkg = packages.first
        expect(pkg.on_hand_quantity).to eql(2)
        expect(pkg.received_quantity).to eql(2)
      end
    end
  end

  context "generate_q_inventory_number" do
    let(:qty_to_split) { 5 }
    let(:package) { create(:package, inventory_number: inventory_number) }

    context "creates first sequential Q number" do
      let(:inventory_number) { "F00001" }
      it { expect(package_splitter.send(:generate_q_inventory_number)).to eql("F00001Q1") }
    end

    context "creates 2nd sequential Q number" do
      let(:inventory_number) { "F00001" }
      it do
        create(:package, inventory_number: "F00001Q1")
        expect(package_splitter.send(:generate_q_inventory_number)).to eql("F00001Q2")
      end
    end

    context "creates next Q number for out of sequence inventory numbers (Q1, Q2, Q5)" do
      let(:inventory_number) { "F00001" }
      it do
        create(:package, inventory_number: "F00001Q1")
        create(:package, inventory_number: "F00001Q2")
        create(:package, inventory_number: "F00001Q5")
        expect(package_splitter.send(:generate_q_inventory_number)).to eql("F00001Q6")
      end
    end

    context "creates next Q number when base package is already a Q number" do
      let(:inventory_number) { "F00001Q1" }
      it { expect(package_splitter.send(:generate_q_inventory_number)).to eql("F00001Q2") }
    end

  end

end
