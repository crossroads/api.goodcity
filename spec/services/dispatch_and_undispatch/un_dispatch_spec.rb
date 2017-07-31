require "rails_helper"

module DispatchAndUndispatch
 describe UnDispatch do

  before(:all) do
    @package = create :package, :with_set_item, received_quantity: 140, quantity: 140
    @order   = create :order
    @orders_package = create :orders_package, :with_state_requested, sent_on: Date.today
    @quantity = 2
  end

  describe 'instance methods' do
    subject { described_class.new(@orders_package, @package, @quantity) }

    describe '#new' do
      it 'initializes class variables' do
        expect(subject.package).to eq @package
        expect(subject.orders_package).to eq @orders_package
        expect(subject.package_location_qty).to eq @quantity
      end
    end

    describe '#undispatch_orders_package' do
      let!(:orders_package) { create :orders_package, :with_state_requested, sent_on: Date.today }
      let!(:un_dispatch) { described_class.new(orders_package, @package, @quantity) }

      it 'sets state as designated' do
        expect{
          un_dispatch.undispatch_orders_package
        }.to change(orders_package, :state).to('designated')
      end

      it 'sent_on to nil' do
        expect{
          un_dispatch.undispatch_orders_package
        }.to change(orders_package, :sent_on).to(nil)
      end
    end
  end

 end
end
