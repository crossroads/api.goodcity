require "rails_helper"
require "goodcity/detail_factory"

describe Goodcity::DetailFactory do
  let(:item_params) {  }
  let(:pacakge) {}
  let(:detail_factory) { described_class.new(item_params, package) }

  before do
    stub_request(:get, /goodcitystorage.blob.core.windows.net/).
      with(headers: { "Accept" => "*/*", "User-Agent" => "Ruby" }).
      to_return(status: 200, body: file, headers: {}).response.body
  end
end
