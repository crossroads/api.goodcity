require 'rails_helper'

context "Code generation validator" do

  context 'for first shipment order' do
    before { Order.destroy_all }
    it 'creates with code S000001' do
      shipment = create(:order, :with_state_draft, :shipment)
      expect(shipment.code).to eq('S00001')
    end
  end

  context 'for subsequent shipment orders' do
    before do
      Order.destroy_all
      create(:order, :with_state_draft, :shipment)
    end
    it 'creates incremental codes' do
      shipment2 = create(:order, :with_state_draft, :shipment)
      shipment3 = create(:order, :with_state_draft, :shipment)
      shipment4 = create(:order, :with_state_draft, :shipment)
      expect(shipment2.code).to eq('S00002')
      expect(shipment3.code).to eq('S00003')
      expect(shipment4.code).to eq('S00004')
    end
  end

  context 'shipment and remote shipment are treated in same sequence' do
    before do
      Order.destroy_all
      create(:order, :with_state_draft, :shipment)
    end
    it 'creates incremental codes' do
      remote_shipment = create(:order, :with_state_draft, :remote_shipment)
      expect(remote_shipment.code).to eq('S00002') # i.e. not S00001
    end
  end

  context "shipment, remote shipment, carryout & GoodCity sequence: S00001, S00002, C00001, GC-00001" do
    before do
      Order.destroy_all
    end
    it do
      shipment = create(:order, :with_state_draft, :shipment)
      remote_shipment = create(:order, :with_state_draft, :remote_shipment)
      carry_out = create(:order, :with_state_draft, :carry_out)
      gc_order = create(:order, :with_state_draft, detail_type: "GoodCity")
      expect(shipment.code).to eq('S00001')
      expect(remote_shipment.code).to eq('S00002') # i.e. not S00001
      expect(carry_out.code).to eq('C00001') # i.e. not S00003
      expect(gc_order.code).to eq('GC-00001') # i.e. not S00004 or C00002
    end
  end

  context 'shipments with gaps in sequence' do
    before do
      Order.destroy_all
    end
    it 'choose max + 1' do
      shipment1 = create(:order, :with_state_draft, :shipment) # S00001
      shipment2 = create(:order, :with_state_draft, :shipment) # S00002
      shipment3 = create(:order, :with_state_draft, :shipment) # S00003
      expect(shipment1.code).to eq('S00001')
      expect(shipment2.code).to eq('S00002')
      expect(shipment3.code).to eq('S00003')

      # manually change shipment2 code to create a gap
      shipment2.update_column(:code, 'S00010')

      shipment4 = create(:order, :with_state_draft, :shipment) # should be S00011
      expect(shipment4.code).to eq('S00011')
    end
  end

  context 'for invalid detail_type' do
    it 'raises exception' do
      expect {
        create(:order, detail_type: 'greatcity')
      }.to raise_exception(StandardError)
    end
  end
end
