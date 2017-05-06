require 'ostruct'
require 'classes/diff'
require 'goodcity/compare'
require 'rails_helper'

context Goodcity::Compare do
  
  subject { described_class.new }

  context "initialization" do
    it { expect(subject.diffs).to eql({})}
  end

  context "compare" do
    it do
      expect(subject).to receive(:compare_activities)
      expect(subject).to receive(:compare_boxes)
      expect(subject).to receive(:compare_codes)
      expect(subject).to receive(:compare_countries)
      expect(subject).to receive(:compare_locations)
      expect(subject).to receive(:compare_pallets)
      expect(subject).to receive(:compare_contacts)
      expect(subject).to receive(:compare_local_orders)
      expect(subject).to receive(:compare_organisations)
      expect(subject).to receive(:compare_items)
      expect(subject).to receive(:compare_orders)
      subject.compare
    end
  end

  context "in_words" do
    it "when nothing to say" do
      expect(subject.in_words).to eql("")
    end
    context "removes identical diffs" do
      let(:diff) { double(Diff, identical?: true, klass_name: "TestClass", id: 1) }
      before do
        subject.instance_variable_set("@diffs", {"1" => diff})
      end
      it { expect(subject.in_words).to eql ("") }
    end
  end

  context "compare methods" do
    let(:stockit_payload) { [] }
    before do
      expect(subject).to receive(:stockit_json).with(stockit_klass, root_node).and_return(stockit_payload)
      expect(subject).to receive(:compare_objects).with(goodcity_klass, stockit_payload, sync_attributes)
    end
    
    context "compare_activities" do
      let(:root_node) { "activities" }
      let(:stockit_klass) { Stockit::ActivitySync }
      let(:goodcity_klass) { StockitActivity }
      let(:sync_attributes) { [:name] }
      it { subject.compare_activities }
    end

    context "compare_boxes" do
      let(:root_node) { "boxes" }
      let(:stockit_klass) { Stockit::BoxSync }
      let(:goodcity_klass) { Box }
      let(:sync_attributes) { [:pallet_id, :description, :box_number, :comments] }
      it { subject.compare_boxes }
    end

    context "compare_codes" do
      let(:root_node) { "codes" }
      let(:stockit_klass) { Stockit::CodeSync }
      let(:goodcity_klass) { PackageType }
      let(:sync_attributes) { [:location_id, :code] }
      it { subject.compare_codes }
    end

    context "compare_countries" do
      let(:root_node) { "countries" }
      let(:stockit_klass) { Stockit::CountrySync }
      let(:goodcity_klass) { Country }
      let(:sync_attributes) { [:name_en] }
      it { subject.compare_countries }
    end

    context "compare_locations" do
      let(:root_node) { "locations" }
      let(:stockit_klass) { Stockit::LocationSync }
      let(:goodcity_klass) { Location }
      let(:sync_attributes) { [:area, :building] }
      it { subject.compare_locations }
    end

    context "compare_pallets" do
      let(:root_node) { "pallets" }
      let(:stockit_klass) { Stockit::PalletSync }
      let(:goodcity_klass) { Pallet }
      let(:sync_attributes) { [:pallet_number, :description, :comments] }
      it { subject.compare_pallets }
    end

    context "compare_contacts" do
      let(:root_node) { "contacts" }
      let(:stockit_klass) { Stockit::ContactSync }
      let(:goodcity_klass) { StockitContact }
      let(:sync_attributes) { [:first_name, :last_name, :phone_number, :mobile_phone_number] }
      it { subject.compare_contacts }
    end

    context "compare_local_orders" do
      let(:root_node) { "local_orders" }
      let(:stockit_klass) { Stockit::LocalOrderSync }
      let(:goodcity_klass) { StockitLocalOrder }
      let(:sync_attributes) { [:purpose_of_goods, :hkid_number, :reference_number, :client_name] }
      it { subject.compare_local_orders }
    end

    context "compare_organisations" do
      let(:root_node) { "organisations" }
      let(:stockit_klass) { Stockit::OrganisationSync }
      let(:goodcity_klass) { StockitOrganisation }
      let(:sync_attributes) { [:name] }
      it { subject.compare_organisations }
    end

    context "compare_orders" do
      let(:root_node) { "designations" }
      let(:stockit_klass) { Stockit::DesignationSync }
      let(:goodcity_klass) { Order }
      let(:sync_attributes) { [:code, :country_id, :description, :detail_id, :detail_type, :organisation_id, :status] }
      it { subject.compare_orders }
    end

  end

  context "compare_objects" do
    let(:goodcity_klass) { StockitActivity }
    let(:stockit_objects) { [{"name" => "Name"}] }
    let(:attributes_to_compare) { [:name] }

    context "with missing stockit object" do
      before do
        FactoryGirl.create(:stockit_activity, name: "Name")
        subject.send(:compare_objects, goodcity_klass, stockit_objects, attributes_to_compare)
      end
      let(:stockit_objects) { [] }
      it { expect(subject.diffs.values.size).to eql(1) }
      it { expect(subject.diffs.values.first.diff[:name]).to eql( ["Name", nil] ) }
    end

    context "with missing goodcity object" do
      before do
        subject.send(:compare_objects, goodcity_klass, stockit_objects, attributes_to_compare)
      end
      it { expect(subject.diffs.values.size).to eql(1) }
      it { expect(subject.diffs.values.first.diff[:name]).to eql( [nil, "Name"] ) }
    end

    context "with different stockit object" do
      let(:stockit_objects) { [{"name" => "Name2"}] }
      before do
        FactoryGirl.create(:stockit_activity, name: "Name")
        subject.send(:compare_objects, goodcity_klass, stockit_objects, attributes_to_compare)
      end
      it { expect(subject.diffs.values.size).to eql(1) }
      it { expect(subject.diffs.values.first.diff[:name]).to eql( ["Name", "Name2"] ) }
    end

    context "with different goodcity object" do
      before do
        FactoryGirl.create(:stockit_activity, name: "Name2")
        subject.send(:compare_objects, goodcity_klass, stockit_objects, attributes_to_compare)
      end
      it { expect(subject.diffs.values.size).to eql(1) }
      it { expect(subject.diffs.values.first.diff[:name]).to eql( ["Name2", "Name"] ) }
    end

    context "with identical objects" do
      before do
        FactoryGirl.create(:stockit_activity, name: "Name")
        subject.send(:compare_objects, goodcity_klass, stockit_objects, attributes_to_compare)
      end
      it { expect(subject.diffs.values.size).to eql(1) }
      it { expect(subject.diffs.values.first.diff).to eql({}) }
    end

  end

  context "compare_items / paginated_json" do
    let(:stockit_hash) { [{"box_id" => 1}] }
    let(:stockit_json) { {"items" => stockit_hash.to_json } }
    it do
      expect(Stockit::ItemSync).to receive(:index).with(nil, 0, 1000).and_return(stockit_json)
      expect(Stockit::ItemSync).to receive(:index).with(nil, 1000, 1000).and_return("items" => "[]")
      expect(subject).to receive(:compare_objects).with(Package, stockit_hash, [:box_id, :case_number, :code_id, :condition, :description, :grade, :height, :inventory_number, :length, :location_id, :pallet_id, :quantity, :sent_on, :width])
      subject.compare_items
    end
  end

  context "stockit_json" do
    let(:stockit_hash) { [{"box_id" => 1}] }
    let(:stockit_json) { {"items" => stockit_hash.to_json } }
    let(:klass) { Stockit::ItemSync }
    it do
      expect(klass).to receive(:index).and_return(stockit_json)
      expect(subject.send(:stockit_json, klass, "items")).to eql(stockit_hash)
    end
    it "handles empty payload" do
      expect(klass).to receive(:index).and_return("[]")
      expect(subject.send(:stockit_json, klass, "items")).to eql([])
    end
  end

end