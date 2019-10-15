require "rails_helper"

describe Stockit::ItemDetailSync do
  let(:endpoint) { "http://www.example.com" }
  let(:connection_error_response) { connection_error_response = { connection_error: "Could not contact Stockit, try again later."} }

  before do
    allow(Stockit::ItemDetailSync).to receive(:create).and_return(@success_response)
    @computer = create :computer
    @success_response = { "status" => 201 , "computer_id" => @computer.id}
    @detail_type = @computer.class.name.underscore
    @stockit = described_class.new(@computer)
    @options = @stockit.send(:default_options)
    @mock_response = double( as_json: @success_response )
  end

  describe "initialize" do
    it "should set @detail, @detail_type" do
      expect(@stockit.detail).to eql(@computer)
      expect(@stockit.detail_type).to eql(@detail_type)
    end
  end

  describe "create" do
    let(:url) { "#{endpoint}/api/v1/#{@detail_type.pluralize}" }
    let(:detail_params) { @stockit.send(:detail_params) }

    it "should send create request and get success_response" do
      expect( Nestful ).to receive(:post).with( url, detail_params, @options ).and_return( @mock_response )
      expect(@stockit.create).to eql( @success_response )
    end

    it "should handle error case" do
      expect( Nestful ).to receive(:post).and_raise(Nestful::ConnectionError, connection_error_response )
      expect(@stockit.create).to eql( "errors" => connection_error_response  )
    end
  end

  describe "update" do
    let(:url) { "#{endpoint}/api/v1/#{@detail_type.pluralize}/update" }
    let(:detail_params) { @stockit.send(:detail_params) }

    it "should send update request and get success_response" do
      expect( Nestful ).to receive(:put).with( url, detail_params, @options ).and_return( @mock_response )
      expect(@stockit.update).to eql( @success_response )
    end

    it "should handle error case" do
      expect( Nestful ).to receive(:put).and_raise(Nestful::ConnectionError, connection_error_response )
      expect(@stockit.update).to eql( "errors" => connection_error_response  )
    end
  end
end
