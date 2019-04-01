require "rails_helper"

 describe "Designator.new" do
  let(:order) { create :order, :with_stockit_id }
  let(:order1) { create :order, :with_stockit_id }
  let(:package) { create :package, :stockit_package, quantity: 1, received_quantity: 1 }
  let(:package1) { create :package, :stockit_package, quantity: 0, received_quantity: 1 }
  let!(:designated_orders_package) { create :orders_package, :with_state_designated, quantity: 1, package_id: package.id, order_id: order1.id}
  let(:orders_package) do
    FactoryBot.build(:orders_package, :with_state_requested, id: nil, package_id: package.id, order_id: nil, quantity:nil)
  end

  let(:designate_package_params) {
    { quantity: "1",order_id: order.id,package_id: package.id,received_quantity: "1",orders_package_id: '' }
  }

  let(:redesignate_package_params) {
    { quantity: "0",order_id: order1.id,package_id: package1.id,received_quantity: "1",orders_package_id: designated_orders_package.id }
  }

  let(:designator) { Designator.new(package, designate_package_params) }
  let(:designator_with_designated_package) { Designator.new(package1, redesignate_package_params) }
  let(:designator_for_undesignating_package) { Designator.new(package1, {"0"=>redesignate_package_params.stringify_keys} )}

  context "initialization" do
    it { expect(designator.instance_variable_get("@package")).to eql(package) }
    it { expect(designator.instance_variable_get("@params")).to eql(designate_package_params) }
    it { expect(designator.instance_variable_get("@order_id")).to eql(order.id) }
    it { expect(designator.instance_variable_get("@orders_package").package_id).to eql(orders_package.package_id) }
  end

  context ".designate" do
    before(:all) do
      WebMock.disable!
    end

    after(:all) do
      WebMock.enable!
    end

    it "designates packages to order if not designated" do
      designator.designate
      expect(order.orders_packages.length).to eq(1)
      expect(order.orders_packages.first.order_id).to eq(order.id)
    end

    it "undesignate before designating to new order" do
      designator_with_designated_package.designate
      expect(order1.orders_packages.first.order_id).to eq(redesignate_package_params[:order_id])
      expect(order.orders_packages.length).to eq(0)
    end

    it "return error message if package already designated to same order" do
      expect(designator_with_designated_package.designate.errors.full_messages).to eq(["Package Already designated to this Order"])
    end

    it "return no error message if package is not designated to same order" do
      expect(designator.designate&.errors.full_messages).to eq([])
    end

  end

  context ".undesignate" do
    before(:all) do
      WebMock.disable!
    end

    after(:all) do
      WebMock.enable!
    end

    it "undesignate package from order" do
      expect{
        designator_for_undesignating_package.undesignate
      }.to change{order1.orders_packages.count}.by(0)
    end
  end
end
