require 'rails_helper'

RSpec.describe Api::V1::ApiController, type: :controller do

  before { generate_and_set_token }

  subject { JSON.parse(response.body) }

  context "handling ActiveRecord::RecordNotFound exceptions" do

    controller do
      def index
        raise ActiveRecord::RecordNotFound
      end
    end

    it do
      get :index
      expect(response.status).to eq(404)
      expect(subject).to eql( {} )
    end

  end

  context "handling CanCan::AccessDenied exceptions" do

    controller do
      def index
        raise CanCan::AccessDenied
      end
    end

    it do
      get :index, format: 'json'
      expect(response.status).to eq(403)
    end

  end

  context "handling Apipie::ParamInvalid exceptions" do

    let(:error_msg) { "Invalid parameter 'language' value \"test\": Must be one of: en, zh-tw." }

    controller do
      def index
        raise Apipie::ParamInvalid.new("language", "test", "Must be one of: en, zh-tw.")
      end
    end

    it do
      get :index
      expect(response.status).to eq(422)
      expect(subject['error']).to eql(error_msg)
    end
  end

  context "per_page" do
    subject { controller.per_page }

    before(:each) do
      controller.params[:per_page] = per_page
    end

    context "20 per page" do
      let(:per_page) { '20' }
      it { expect(subject).to eql(20) }
    end

    context "30 per_page (limit is 25)" do
      let(:per_page) { '30' }
      it { expect(subject).to eql(25) }
    end

    context "nil per_page" do
      let(:per_page) { nil }
      it { expect(subject).to eql(25) }
    end

    context "blank per_page" do
      let(:per_page) { '' }
      it { expect(subject).to eql(25) }
    end

    context "blah per_page" do
      let(:per_page) { 'blah' }
      it { expect(subject).to eql(25) }
    end
  end
end
