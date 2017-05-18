require "rails_helper"

describe Stockit::OrdersPackageSync do
  let(:package) { create :package, :stockit_package }
  let(:package_without_inventory) { create :package }
  let(:orders_package) { create :orders_package }
  let(:stockit)  { described_class.new(package, orders_package) }
  let(:stockit_without_inventory) { described_class.new(package_without_inventory, orders_package) }
  let(:endpoint) { "http://www.example.com" }
  let(:options)  { stockit.send(:default_options) }
  let(:mock_response)       { double( as_json: success_response ) }
  let(:success_response)    { { "status" => 201 } }

  describe 'initialize' do
    it 'sets @package' do
      expect(stockit.package).to eq package
    end

    it 'sets @orders_package' do
      expect(stockit.orders_package).to eq orders_package
    end
  end

  describe 'create' do
    let(:url) { "#{endpoint}/api/v1/items" }
    let(:stockit_params) { stockit.send(:stockit_params) }

    it "sends create request and get success_response" do
      stockit_params_for_inventory_number_presence = stockit_params.merge({generate_q_inventory_number: true})
      expect( Nestful ).to receive(:post).with( url, stockit_params_for_inventory_number_presence, options ).and_return( mock_response )
      expect(stockit.create).to eql( success_response )
    end

    it 'do not create request and get succees_response if inventory number for package not exist' do
      expect( Nestful ).to_not receive(:post).with( url, stockit_params, options )
      expect(stockit_without_inventory.create).to eql( nil )
    end
  end

  describe 'delete' do
    let(:url) { "#{endpoint}/api/v1/items/destroy" }
    let(:delete_request_params) { {gc_orders_package_id: orders_package} }

    it "sends delete request and get success_response" do
      expect( Nestful ).to receive(:put).with( url, delete_request_params, options ).and_return( nil )
      expect(stockit.delete).to be_nil
    end
  end

  describe 'update' do
    let(:url) { "#{endpoint}/api/v1/items/update" }
    let(:stockit_params) { stockit.send(:stockit_params) }

    it "sends update request and get success_response" do
      stockit_param_for_inventory = stockit_params.merge({update_gc_orders_package: true,
        orders_package_id: orders_package.id, orders_package_state: orders_package.state})
      expect( Nestful ).to receive(:put).with( url, stockit_param_for_inventory, options ).and_return( mock_response )
      expect(stockit.update).to eql( success_response )
    end

    it "do not send update request if inventory_number is blank" do
      expect( Nestful ).to_not receive(:put).with(url, stockit_params, options)
      expect(stockit_without_inventory.update).to eql( nil )
    end
  end
end
