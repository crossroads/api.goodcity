require "rails_helper"

module DispatchAndUndispatch
 describe Base do

    before(:all) do
      @package = create :package
      @order   = create :order
      @orders_package = create :orders_package
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
    end
 end
end
