require "rails_helper"

module DesignationAndUndesignation
  describe NewDesignation do
    before(:all) do
      @package = create :package, received_quantity: 10, quantity: 10
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

      describe '#designate_partial_item' do
        it 'creates new orders_package with state designated' do
          expect{
            subject.designate_partial_item
          }.to change(OrdersPackage, :count).by(1)
          new_orders_package = OrdersPackage.where(order_id: @order.id, package_id: @package.id).first
          expect(new_orders_package.quantity).to eq @quantity
          expect(new_orders_package.state).to eq('designated')
        end

        it 'updates changes package quantity to remaining quantity(i.e quantity which is not yet designated)' do
          remaining_quantity = @package.received_quantity - @quantity
          expect{
            subject.designate_partial_item
          }.to change(@package.reload, :quantity).to(remaining_quantity)
        end
      end
    end
  end
end
