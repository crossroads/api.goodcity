require "rails_helper"

describe Stockit::Browse do
  let(:package)  { create :package, :with_item }
  let(:stockit)  { described_class.new(package) }
  let(:endpoint) { "http://www.example.com" }
  let(:options)  { { format: :json, headers: {} } }
  let(:connection_error_response) {
    { connection_error: "Could not contact Stockit, try again later."}
  }

  describe "initialize" do
    it "should set @gc_package" do
      expect( stockit.gc_package ).to eql(package)
    end
  end

  describe "add_item" do

    let(:url) { "#{endpoint}/api/v1/items" }
    let(:stockit_params) { stockit.send(:stockit_params) }

    let(:success_response) { { "status" => 201 } }
    let(:mock_response) { double( as_json: success_response ) }

    let(:error_response) { { "errors" => { "code" => "can't be blank" } } }
    let(:mock_error_response) { double( as_json: error_response ) }

    it "should request add_item and get success_response" do
      expect( Nestful ).to receive(:post).with( url, stockit_params, options ).and_return( mock_response )
      expect(stockit.add_item).to eql( success_response )
    end

    it "should request add_item and get error_response" do
      expect( Nestful ).to receive(:post).with( url, stockit_params, options ).and_return( mock_error_response )
      expect(stockit.add_item).to eql( error_response )
    end

    it "should handle error case" do
      expect( Nestful ).to receive(:post).and_raise(Nestful::ConnectionError, connection_error_response )
      expect(stockit.add_item).to eql( errors: connection_error_response  )
    end

  end

  describe "remove_item" do

    let(:stockit_package) { create :package, :stockit_package }
    let(:stockit_remove)  { described_class.new(stockit_package.inventory_number) }

    let(:url) { "#{endpoint}/api/v1/items/destroy" }
    let(:delete_request_params) { stockit_remove.send(:delete_request_params) }

    let(:error_response) { { "errors" => { "dispatched" => "Designated or dispatched items cannot be marked missing." } } }
    let(:mock_error_response) { double( as_json: error_response ) }

    it "should request remove_item and get success_response" do
      expect( Nestful ).to receive(:put).with( url, delete_request_params, options ).and_return( nil )
      expect(stockit_remove.remove_item).to be_nil
    end

    it "should request remove_item and get error_response" do
      expect( Nestful ).to receive(:put).with( url, delete_request_params, options ).and_return( mock_error_response )
      expect(stockit_remove.remove_item).to eql( error_response )
    end

    it "should handle error case" do
      expect( Nestful ).to receive(:put).and_raise(Nestful::ConnectionError, connection_error_response )
      expect(stockit_remove.remove_item).to eql( errors: connection_error_response  )
    end

    it "should not contact stockit if not have inventory number" do
      stockit = described_class.new(package.inventory_number)
      expect(stockit.remove_item).to be_nil
    end

  end

end
