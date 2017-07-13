require "rails_helper"

module DesignationAndUndesignation
  describe Base do

    before(:all) do
      @package = create :package
      @order   = create :order
      @quantity = 2
    end

    describe 'instance methods' do
      subject { described_class.new(@package, @order.id, @quantity) }

      describe '#new' do
        it 'initializes class variables' do
          expect(subject.package).to eq @package
          expect(subject.order_id).to eq @order.id
          expect(subject.quantity).to eq @quantity
        end
      end

      describe '#operation_for_sync' do
        it 'returns create operation if orders_package record is newly created' do
          subject.is_new_orders_package = true
          expect(subject.operation_for_sync).to eq 'create'
        end

        it 'returns update operation if orders_package record already exist' do
          subject.is_new_orders_package = false
          expect(subject.operation_for_sync).to eq 'update'
        end
      end

      describe '#dispatched_location_id' do
        let!(:dispatched_location) { create :location, :dispatched }

        it 'returns dispatched location id' do
          expect(subject.dispatched_location_id).to eq dispatched_location.id
        end
      end

      describe '#dispatched_orders_packages' do
        it 'returns dispatched orders_packages associated with package' do
          @orders_package = create :orders_package, order: @order, package: @package, state: 'dispatched'
          expect(subject.dispatched_orders_packages.count).to eq 1
        end

        it 'returns no records if no associated dispatched orders_packages exist' do
          expect(subject.dispatched_orders_packages.count).to eq 0
        end
      end

      describe '#designated_orders_packages' do
        it 'returns designated orders_packages associated with package' do
          @orders_package = create :orders_package, order: @order, package: @package, state: 'designated'
          expect(subject.designated_orders_packages.count).to eq 1
        end

        it 'returns no records if no associated designated orders_packages exist' do
          expect(subject.designated_orders_packages.count).to eq 0
        end
      end

      describe 'is_valid_for_sync' do
        it 'returns true if orders_package state is not requested and request is not coming from stockit' do
          @orders_package = create :orders_package, order: @order, package: @package, state: 'designated'
          subject.orders_package = @orders_package
          expect(subject.is_valid_for_sync?).to eq true
        end

        it 'returns false if orders_package state is not requested but request is coming from stockit' do
          @orders_package = create :orders_package, order: @order, package: @package, state: 'requested'
          subject.orders_package = @orders_package
          expect(subject.is_valid_for_sync?).to eq false
        end
      end
    end
  end
end
