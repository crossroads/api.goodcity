require "rails_helper"

describe Stockit::Location do
  let(:endpoint) { "http://www.example.com" }

  let(:params) { {} }
  let(:token) { Rails.application.secrets.stockit["api_token"] }
  let(:options) { { format: :json, headers: {"token" => token} } }
  let(:success_response) { { "status" => 200 } }
  let(:mock_response) { double(as_json: success_response) }
  let(:connection_error_response) {
    { connection_error: ": could not contact Stockit, try again later."}
  }

  describe "index" do

    let(:url) { "#{endpoint}/api/v1/locations" }

    it "should send successful get request" do
      expect(Nestful).to receive(:get).with(url, params, options).and_return(mock_response)
      expect(Stockit::Location.index).to eql(success_response)
    end

  end

end
