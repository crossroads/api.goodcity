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

      describe '#update_designation_of_package' do
        before(:all) do
          @package = create :package, received_quantity: 1, quantity: 0
          @undesignated_package = create :package, received_quantity: 1, quantity: 1
          @designated_orders_package = create :orders_package, quantity: 1,
            state: 'designated', package: @package
        end

        it 'sets order_id of package same as orders_package order_id when its designated' do
          subject.package = @package
          subject.update_designation_of_package
          expect(@package.reload.order_id).to eq @designated_orders_package.order_id
        end

        it 'removes order_id of package if none of the orders_packages are designated and dispatched' do
          subject.package = @undesignated_package
          subject.update_designation_of_package
          expect(@undesignated_package.reload.order_id).to eq nil
        end
      end

      describe '#recalculate_package_quantity' do
        let(:package) { create :package, received_quantity: 1, quantity: 1 }

        context 'recalculates package quantity and assigns order_id to package when designated orders_package created' do
          before(:each) do
            @designated_orders_package = create :orders_package, quantity: 1,
              state: 'designated', package: @package
            subject.package = @package
            subject.orders_package = @designated_orders_package
            subject.recalculate_package_quantity
          end

          it 'recalculates package quantity after some of its quantity designated' do
            expect(@package.reload.quantity).to eq 0
          end

          it 'updates designation(order_id) of package when some of its quantity is designated' do
            expect(@package.order_id).to eq @designated_orders_package.order_id
          end
        end

        it 'do not recalculates quantity if its not valid for sync' do
          requested_orders_package = build :orders_package, state: 'requested', package: package,
            quantity: 1
          subject.orders_package = requested_orders_package
          expect(subject.recalculate_package_quantity).to be_nil
        end
      end
    end
  end
end
