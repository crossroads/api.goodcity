require "rails_helper"

module DispatchAndUndispatch
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
    end
 end
end
