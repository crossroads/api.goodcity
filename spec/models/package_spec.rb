require 'rails_helper'
require "rspec/mocks/standalone"

RSpec.describe Package, type: :model do

  before(:all) do
    allow_any_instance_of(Package).to receive(:update_client_store)
  end

  let(:package) { create :package }

  describe "Associations" do
    it { is_expected.to belong_to :item }
    it { is_expected.to belong_to :package_type }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:length).of_type(:integer)}
    it{ is_expected.to have_db_column(:width).of_type(:integer)}
    it{ is_expected.to have_db_column(:height).of_type(:integer)}
    it{ is_expected.to have_db_column(:quantity).of_type(:integer)}
    it{ is_expected.to have_db_column(:notes).of_type(:text)}
    it{ is_expected.to have_db_column(:state).of_type(:string)}
    it{ is_expected.to have_db_column(:received_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:rejected_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:designation_name).of_type(:string)}
    it{ is_expected.to have_db_column(:grade).of_type(:string)}
    it{ is_expected.to have_db_column(:donor_condition_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:saleable).of_type(:boolean)}
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:package_type_id) }

    let(:attributes) { [:width, :length, :height] }
    it { attributes.each { |attribute| is_expected.to allow_value(nil).for(attribute) } }

    it do
      [:quantity, :length].each do |attribute|
        is_expected.to_not allow_value(-1).for(attribute)
        is_expected.to_not allow_value(100000000).for(attribute)
        is_expected.to allow_value(rand(1..99999999)).for(attribute)
      end
    end

    it do
      [:width, :height].each do |attribute|
        is_expected.to_not allow_value(0).for(attribute)
        is_expected.to_not allow_value(100000).for(attribute)
        is_expected.to allow_value(rand(1..99999)).for(attribute)
      end
    end
  end

  describe "state" do
    describe "#mark_received" do
      it "should set received_at value" do
        expect(Stockit::ItemSync).to receive(:create).with(package)
        expect{
          package.mark_received
        }.to change(package, :received_at)
        expect(package.state).to eq("received")
      end
    end

    describe "#mark_missing" do
      let(:package) { create :package, :received }
      it "should set received_at value" do
        expect(Stockit::ItemSync).to receive(:delete).with(package.inventory_number)
        expect{
          package.mark_missing
        }.to change(package, :received_at).to(nil)
        expect(package.state).to eq("missing")
      end
    end
  end

  describe "add_to_stockit" do
    it "should add API errors to package.errors" do
      api_response = {"errors" => {"code" => "can't be blank"}}
      expect(Stockit::ItemSync).to receive(:create).with(package).and_return(api_response)
      package.add_to_stockit
      expect(package.errors).to include(:code)
    end
  end

  describe "remove_from_stockit" do
    it "should add API errors to package.errors" do
      package.inventory_number = "F12345"
      api_response = {"errors" => {"base" => "already designated"}}
      expect(Stockit::ItemSync).to receive(:delete).with(package.inventory_number).and_return(api_response)
      package.remove_from_stockit
      expect(package.errors).to include(:base)
      expect(package.inventory_number).to_not be_nil
    end

    it "should add set inventory_number to nil" do
      package.inventory_number = "F12345"
      expect(Stockit::ItemSync).to receive(:delete).with(package.inventory_number).and_return({})
      package.remove_from_stockit
      expect(package.errors.full_messages).to eq([])
      expect(package.inventory_number).to be_nil
    end
  end

  describe "#offer" do
    it "should return related offer" do
      package = create :package, :with_item
      expect(package.offer).to eq(package.item.offer)
    end
  end

  context "has_paper_trail" do
    it { is_expected.to be_versioned }
  end

  describe "before_save" do
    it "should set default values" do
      item = create :item
      package = build :package, item: item
      expect {
        package.save
      }.to change(package, :donor_condition).from(nil).to(item.donor_condition)
      expect(package.grade).to eq("B")
      expect(package.saleable).to eq(item.offer.saleable)
    end
  end

  describe 'set_item_id' do

    let(:item) { create :item }

    it 'update set_item_id value on receiving sibling package' do
      package = create :package, :stockit_package, item: item
      sibling_package = create :package, :stockit_package, item: item
      expect(Stockit::ItemSync).to receive(:create).with(sibling_package)

      expect {
        sibling_package.mark_received
        package.reload
      }.to change(package, :set_item_id).from(nil).to(item.id)
    end

    describe 'removing set_item_id from package' do
      let!(:package) { create :package, :with_set_item, item: item }
      let!(:sibling_package) { create :package, :with_set_item, item: item }

      it 'update set_item_id value on missing sibling package' do
        expect(Stockit::ItemSync).to receive(:delete).with(sibling_package.inventory_number)

        expect {
          sibling_package.mark_missing
          package.reload
        }.to change(package, :set_item_id).from(item.id).to(nil)
      end

      describe 'remove_from_set' do
        it 'removes package from set' do
          expect {
            sibling_package.remove_from_set
            package.reload
          }.to change(package, :set_item_id).from(item.id).to(nil)
          expect(sibling_package.set_item_id).to be_nil
        end
      end
    end
  end

  describe 'dispatch_stockit_item' do
    let(:package) { create :package, :with_set_item }
    let!(:location) { create :location, :dispatched }
    before { expect(Stockit::ItemSync).to receive(:dispatch).with(package) }

    it 'set dispatch related details' do
      package.dispatch_stockit_item
      expect(package.locations.first).to eq(location)
      expect(package.stockit_sent_on).to_not be_nil
    end

    it 'update set relation on dispatching single package' do
      sibling_package = create :package, :with_set_item, item: package.item
      package.dispatch_stockit_item
      package.save
      expect(package.set_item_id).to be_nil
      expect(sibling_package.reload.set_item_id).to be_nil
    end
  end
end
