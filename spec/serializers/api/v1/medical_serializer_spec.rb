# frozen_string_literal: true

require 'rails_helper'

context Api::V1::MedicalSerializer do
  let(:medical) { build(:medical) }
  let(:serializer) { Api::V1::MedicalSerializer.new(medical).as_json }
  let(:json) { JSON.parse(serializer.to_json) }

  it 'cretes JSON' do
    medical.attributes.except('id').keys.each do |key|
      expect(json['medical'][key.to_s].to_s)
        .to eq(medical.send(key.to_s.to_sym).to_s)
    end
  end

  %i[id brand serial_number expiry_date updated_by_id model].map do |attr|
    it "should have #{attr} in response" do
      expect(json['medical'].keys).to include(attr.to_s)
    end
  end

  context 'include_country is false' do
    let(:serializer) { Api::V1::MedicalSerializer.new(medical, include_country: false).as_json }
    it 'does not have country in the json' do
      expect(json.keys).not_to include('country')
    end
  end

  context 'include_country is true' do
    let(:serializer) { Api::V1::MedicalSerializer.new(medical, include_country: true).as_json }
    let(:json) { JSON.parse(serializer.to_json) }
    it 'includes country in the json' do
      expect(json.keys).to include('countries')
    end
  end
end
