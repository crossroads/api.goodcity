require 'rails_helper'

describe InventoryLegacySupport do
  let(:user) { create(:user) }
  let(:packages_location) { create(:packages_location, quantity: quantity) }
  let(:package) { packages_location.package }
  let(:computer) { PackagesInventory::Computer }

  before { User.current_user = user }

  describe "Syncing PackagesLocation <-> PackagesInventory" do

    # [First direction]
    #
    # PackagesLocation ---> PackagesInventory
    #
    context "Changing packages_locationns" do

      context "by creating a new PackagesLocation" do

        context "with positive quantity" do
          let(:quantity) { 13 }

          it "records a GAIN in the inventory" do
            expect {
              touch(packages_location)
            }.to change(PackagesInventory, :count).by(1)

            expect(PackagesInventory.count).to eq(1)
            record = PackagesInventory.first
            expect(record.quantity).to eq(quantity)
            expect(record.package).to eq(packages_location.package)
            expect(record.location).to eq(packages_location.location)
            expect(record.action).to eq('gain')
            expect(record.source).to be_nil
          end
        end

        context "with zero quantity" do
          let(:quantity) { 0 }

          before { touch(packages_location) }

          it "doesn't record anything in the inventory" do
            expect { touch(packages_location) }.not_to change(PackagesInventory, :count)
          end
        end
      end

      context "by updating a PackagesLocation" do
        let(:quantity) { 13 }

        before { touch(packages_location) }

        context "by increasing it's quantity" do
          let(:added_quantity) { 10 }

          it "records a GAIN in the inventory" do
            expect {
              packages_location.increment!(:quantity, added_quantity)
            }.to change(PackagesInventory, :count).by(1)

            expect(PackagesInventory.count).to eq(2)
            record = PackagesInventory.last
            expect(record.quantity).to eq(added_quantity)
            expect(record.package).to eq(packages_location.package)
            expect(record.location).to eq(packages_location.location)
            expect(record.action).to eq('gain')
            expect(record.source).to be_nil
          end

          it "accounts in the total computed quantity" do
            expect {
              packages_location.increment!(:quantity, added_quantity)
            }.to change {
              computer.package_quantity(package).now
            }.by(added_quantity)

            expect(computer.package_quantity(package).now).to eq(quantity + added_quantity)
          end
        end

        context "by decreasing it's quantity" do
          let(:removed_quantity) { 10 }

          it "records a LOSS in the inventory" do
            expect {
              packages_location.decrement!(:quantity, removed_quantity)
            }.to change(PackagesInventory, :count).by(1)

            expect(PackagesInventory.count).to eq(2)
            record = PackagesInventory.last
            expect(record.quantity).to eq(-1 * removed_quantity)
            expect(record.package).to eq(packages_location.package)
            expect(record.location).to eq(packages_location.location)
            expect(record.action).to eq('loss')
            expect(record.source).to be_nil
          end

          it "accounts in the total computed quantity" do
            expect {
              packages_location.decrement!(:quantity, removed_quantity)
            }.to change {
              computer.package_quantity(package).now
            }.by(-1 * removed_quantity)

            expect(computer.package_quantity(package).now).to eq(quantity - removed_quantity)
          end
        end
      end

      context "by deleting a PackagesLocation" do

        context "which had positive quantity" do
          let(:quantity) { 13 }

          before { touch(packages_location) }

          it "records a LOSS in the inventory" do
            expect {
              packages_location.destroy
            }.to change(PackagesInventory, :count).by(1)

            expect(PackagesInventory.count).to eq(2)
            record = PackagesInventory.last
            expect(record.quantity).to eq(-1 * quantity)
            expect(record.package).to eq(packages_location.package)
            expect(record.location).to eq(packages_location.location)
            expect(record.action).to eq('loss')
            expect(record.source).to be_nil
          end

          it "accounts in the total computed quantity" do
            expect {
              packages_location.destroy
            }.to change {
              computer.package_quantity(package).now
            }.by(-1 * quantity)

            expect(computer.package_quantity(package).now).to eq(0)
          end
        end

        context "which had zero quantity" do
          let(:quantity) { 0 }

          before { touch(packages_location) }

          it "doesn't record anything in the inventory" do
            expect { packages_location.destroy }.not_to change(PackagesInventory, :count)
          end
        end
      end
    end
  end
end
