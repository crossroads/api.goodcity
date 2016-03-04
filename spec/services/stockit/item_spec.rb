require "rails_helper"

describe Stockit::Item do
  let(:package)  { create :package, :stockit_package, :with_item }
  let(:inventory_number) { package.inventory_number }
  let(:stockit_inventory_number) { "X#{inventory_number}" }
  let(:stockit)  { described_class.new(package) }
  let(:endpoint) { "http://www.example.com" }
  let(:options)  { stockit.send(:default_options) }

  let(:success_response)    { { "status" => 201 } }
  let(:mock_response)       { double( as_json: success_response ) }
  let(:error_response)      { { "errors" => { "code" => "can't be blank" } } }
  let(:mock_error_response) { double( as_json: error_response ) }
  let(:connection_error_response) {
    { connection_error: "Could not contact Stockit, try again later."}
  }

  describe "initialize" do
    it "should set @package" do
      expect( stockit.package ).to eql(package)
    end
  end

  describe "create" do

    let(:url) { "#{endpoint}/api/v1/items" }
    let(:stockit_params) { stockit.send(:stockit_params) }

    it "should send create request and get success_response" do
      expect( Nestful ).to receive(:post).with( url, stockit_params, options ).and_return( mock_response )
      expect(stockit.create).to eql( success_response )
    end

    it "should send create request and get error_response" do
      expect( Nestful ).to receive(:post).with( url, stockit_params, options ).and_return( mock_error_response )
      expect(stockit.create).to eql( error_response )
    end

    it "should handle error case" do
      expect( Nestful ).to receive(:post).and_raise(Nestful::ConnectionError, connection_error_response )
      expect(stockit.create).to eql( "errors" => connection_error_response  )
    end

    it "should not send create request if inventory_number is blank" do
      allow(package).to receive(:inventory_number).and_return(nil)
      expect( Nestful ).not_to receive(:post)
      stockit.create
    end

  end

  describe "delete" do

    let(:stockit) { described_class.new(inventory_number) }
    let(:url) { "#{endpoint}/api/v1/items/destroy" }
    let(:delete_request_params) { {inventory_number: stockit_inventory_number} }
    let(:error_response) { { "errors" => { "dispatched" => "Designated or dispatched items cannot be marked missing." } } }
    let(:mock_error_response) { double( as_json: error_response ) }

    it "should send delete request and get success_response" do
      expect( Nestful ).to receive(:put).with( url, delete_request_params, options ).and_return( nil )
      expect(stockit.delete).to be_nil
    end

    it "should send delete request and get error_response" do
      expect( Nestful ).to receive(:put).with( url, delete_request_params, options ).and_return( mock_error_response )
      expect(stockit.delete).to eql( error_response )
    end

    it "should handle error case" do
      expect( Nestful ).to receive(:put).and_raise(Nestful::ConnectionError, connection_error_response )
      expect(stockit.delete).to eql( "errors" => connection_error_response  )
    end

    it "should not send delete request if inventory_number is blank" do
      expect(Nestful).to_not receive(:put)
      expect(described_class.new(nil).delete).to be_nil
    end

  end

  describe "update" do

    let(:url) { "#{endpoint}/api/v1/items/update" }
    let(:stockit_params) { stockit.send(:stockit_params) }

    it "should send update request and get success_response" do
      expect( Nestful ).to receive(:put).with( url, stockit_params, options ).and_return( mock_response )
      expect(stockit.update).to eql( success_response )
    end

    it "should send update request and get error_response" do
      expect( Nestful ).to receive(:put).with( url, stockit_params, options ).and_return( mock_error_response )
      expect(stockit.update).to eql( error_response )
    end

    it "should handle error case" do
      expect( Nestful ).to receive(:put).and_raise(Nestful::ConnectionError, connection_error_response )
      expect(stockit.update).to eql( "errors" => connection_error_response  )
    end

    it "should not send update request if inventory_number is blank" do
      allow(package).to receive(:inventory_number).and_return(nil)
      expect(Nestful).to_not receive(:put)
      expect(stockit.update).to be_nil
    end

  end
end
