require 'rails_helper'

RSpec.describe Api::V1::ApiController, type: :controller do

  #subject { JSON.parse(response.body) }

  before { generate_and_set_token }

  context "handling ActiveRecord::RecordNotFound exceptions" do

    subject { JSON.parse(response.body) }

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

    subject { JSON.parse(response.body) }

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

end
