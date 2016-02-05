require "rails_helper"

describe Stockit::Base do

  class StockitBaseTestClass
    include Stockit::Base
  end

  subject { StockitBaseTestClass.new }
  let(:endpoint) { Rails.application.secrets.base_urls["stockit"] }
  let(:api_token) { Rails.application.secrets.stockit["api_token"] }
  let(:headers) { {"token" => api_token} }
  let(:default_options) { { format: :json, headers: headers } }

  describe "stockit_connection_error" do
    it { expect(subject.stockit_connection_error).to be_a(Hash) }
    it { expect(subject.stockit_connection_error["errors"]).to eql(connection_error: "Could not contact Stockit, try again later.") }
  end

  describe "headers" do
    it { expect(subject.headers.keys).to include("token") }
  end

  describe "endpoint" do
    it { expect(subject.endpoint).to eql(endpoint) }
  end

  describe "api_token" do
    it { expect(subject.api_token).to eql(api_token) }
  end

  describe "default_options" do
    it { expect(subject.default_options).to eql(default_options) }
  end

  describe "url_for" do
    it { expect(subject.url_for('/index')).to eql("#{endpoint}/index") }
  end

end
