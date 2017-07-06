require "rails_helper"

module DesignationAndUndesignation
  describe NewDesignation do
    before(:all) do
      @package = create :package, received_quantity: 10
      @order = create :order
      @quantity = 2
    end

    describe 'instance methods' do
      subject { described_class.new(@package, @order.id, @quantity) }

      describe '#new' do
        it 'initializes class variables' do
          expect(subject.package).to eq @package
          expect(subject.order_id).to eq @order.id
          expect(subject.is_new_orders_package).to eq false
          expect(subject.orders_package).to be_nil
          expect(subject.quantity).to eq @quantity
        end
      end
    end
  end
end
