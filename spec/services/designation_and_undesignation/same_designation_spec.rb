require "rails_helper"

module DesignationAndUndesignation
  describe SameDesignation do

    before(:all) do
      @package = create :package, received_quantity: 10
      @package_1 = create :package, received_quantity: 9
      @order = create :order
      @orders_package = create :orders_package, package: @package,
        order: @order, quantity: 8
      @quantity = 2
    end

    describe 'instance_methods' do
      subject { described_class.new(@package, @order.id, @quantity, @orders_package.id) }

      describe '#new' do
        it 'initializes class variables' do
          expect(subject.package).to eq @package
          expect(subject.orders_package).to eq @orders_package
          expect(subject.orders_package_state).to eq @orders_package.state
          expect(subject.is_new_orders_package).to eq false
        end
      end

      describe '#total_designated_quantity' do
        it 'returns total quantity to designate' do
          expect(subject.total_designated_quantity).to eq(@orders_package.quantity + @quantity)
        end
      end

      describe '#all_quantity_dispatched?' do
        it 'returns true if all received quantity dispatched' do
          expect(subject.all_quantity_dispatched?).to eq true
        end

        it 'returns false if all received quantity not dispatched' do
          subject.package = @package_1
          expect(subject.all_quantity_dispatched?).to eq false
        end
      end

      describe '#total_designated_quantity' do
        it 'calculates total quantity to be designated' do
          expect(subject.total_designated_quantity).to eq(@orders_package.quantity + @quantity)
        end
      end

      describe '#operation_for_sync' do
        it 'returns update operation as record for same designation is not newly created' do
          expect(subject.operation_for_sync).to eq "update"
        end
      end

      describe '#update_partial_quantity_of_same_designation' do
      end
    end
  end
end
