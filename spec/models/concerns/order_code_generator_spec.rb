require 'rails_helper'

context "Code generation validator" do
  let(:order) { create(:order, :with_state_draft, :with_orders_packages) }

  context 'Goodcity orders' do
    it "Assigns GC Code" do
      expect(order.code).to include('GC-')
    end
  end

  context 'International orders' do
    before do
      Timecop.freeze(Time.local(2020, Time.current.month, Time.current.day, 12, 0, 0))
    end

    context 'shipment' do
      let(:shipment) { create(:order, :with_state_draft, :shipment) }
      it 'assigns code' do
        expect(shipment.code).to match(/^S/)
      end

      context 'for first shipment order' do
        before { Order.destroy_all }
        it 'creates with code S000001' do
          expect(shipment.code).to eq('S00001')
        end
      end

      context 'for subsequent shipment order' do
        before do
          Order.destroy_all
          create(:order, :with_state_draft, :shipment)
        end
        it 'creates incremental codes' do
          expect(shipment.code).to eq('S00002')
        end
      end

      context 'for shipment order with subsequent remote shipment' do
        before do
          Order.destroy_all
          create(:order, :with_state_draft, :shipment)
        end
        it 'creates incremental codes' do
          remote_shipment = create(:order, :with_state_draft, :remote_shipment)
          expect(remote_shipment.code).to eq('S00002') # i.e. not S00001
        end
      end

    end

    context 'carryout' do
      let(:carryout) { create(:order, :with_state_draft, :carry_out) }
      it 'assigns code' do
        expect(carryout.code).to match(/^C/)
      end
    end

    after do
      Timecop.return
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
