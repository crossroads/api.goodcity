require 'ostruct'
require 'classes/diff'

describe Diff do

  let(:klass_name) { "TestClass" }
  let(:goodcity_name) { "GC Name" }
  let(:stockit_name) { "Stockit Name" }
  let(:goodcity_struct) { OpenStruct.new(id: 1, stockit_id: 2, name: goodcity_name ) }
  let(:stockit_struct) { OpenStruct.new(id: 2, name: stockit_name) }
  let(:sync_attributes) { [:name] }
  let(:diff) { Diff.new(klass_name, goodcity_struct, stockit_struct, sync_attributes) }

  context "initialization" do
    context "should set instance variables" do
      it { expect(diff.instance_variable_get("@klass_name")).to eql(klass_name) }
      it { expect(diff.instance_variable_get("@goodcity_struct")).to eql(goodcity_struct) }
      it { expect(diff.instance_variable_get("@stockit_struct")).to eql(stockit_struct) }
      it { expect(diff.instance_variable_get("@sync_attributes")).to eql(sync_attributes) }
      it { expect(diff.id).to eql(goodcity_struct.id) }
    end
  end

  context "key" do
    context "should generate a key based on ids/stockit_id" do
      it { expect(diff.key).to eql("1:2:2") }
    end
  end

  context "compare" do
    context "should return attribute/value differences" do
      before { diff.compare }
      it { expect(diff.instance_variable_get("@diff")).to eql({name: [goodcity_name, stockit_name]}) }
    end
    context "should be empty if no attribute/value differences" do
      let(:goodcity_name) { "Name" }
      let(:stockit_name) { "Name"}
      before { diff.compare }
      it { expect(diff.instance_variable_get("@diff")).to eql({}) }
    end
    context "should ignore id" do
      let(:goodcity_struct) { OpenStruct.new(id: 1, stockit_id: 2, name: "Name" ) }
      let(:stockit_struct) { OpenStruct.new(id: 2, name: "Name") }
      before { diff.compare }
      it { expect(diff.instance_variable_get("@diff").keys).to_not include(:id) }
    end
    context "should ignore stockit_id" do
      let(:goodcity_struct) { OpenStruct.new(id: 1, stockit_id: 2, name: "Name" ) }
      let(:stockit_struct) { OpenStruct.new(id: 2, stockit_id: 3, name: "Name") }
      before { diff.compare }
      it { expect(diff.instance_variable_get("@diff").keys).to_not include(:stockit_id) }
    end
  end

  context "in words" do
    before { diff.compare }
    it do
      expect(diff.in_words).to eql("TestClass=1 | stockit_id=2 | name={GC Name | Stockit Name}")
    end
    context "identical" do
      let(:stockit_name) { goodcity_name }
      it do
        expect(diff.in_words).to eql("TestClass=1 | stockit_id=2 | Identical")
      end
    end
  end

  context "identical?" do
    before { diff.compare }
    context do
      let(:stockit_name) { goodcity_name }
      it { expect(diff.identical?).to eql(true) }
    end
    context do
      let(:goodcity_name) { "goodcity_name" }
      let(:stockit_name) { "stockit_name" }
      it { expect(diff.identical?).to eql(false) }
    end
  end

  context "<=>" do
    let(:goodcity_struct2) { OpenStruct.new(id: id2, stockit_id: 2, name: goodcity_name ) }
    let(:diff2) { Diff.new(klass_name, goodcity_struct2, stockit_struct, sync_attributes) }
    context "should be ordered correctly" do
      let(:id2) { 2 }
      it do
        expect([diff2, diff].sort).to eql([diff, diff2])
      end
    end
    context "should not error when id is nil" do
      let(:id2) { nil }
      it do
        expect([diff2, diff].sort).to eql([diff2, diff])
      end
    end
  end

end
