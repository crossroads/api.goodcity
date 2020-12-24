require 'rails_helper'

describe Api::V2::ShareableSerializer do

  let(:offer)             { create(:offer) }
  let(:shareable)         { create(:shareable, resource: offer) }
  let(:json)              { Api::V2::ShareableSerializer.new(shareable).as_json }
  let(:attributes)        { json['data']['attributes'] }
  let(:relationships)     { json['data']['relationships'] }
  let(:included_records)  { json['included'] }

  def to_date_string(val)
    return nil if val.nil?
    val.is_a?(String) ? Time.parse(val).utc.to_s : val.utc.to_s
  end

  describe "Attributes" do
    it "includes the correct attributes" do
      expect(attributes['id']).to eq(shareable[:id])
      expect(attributes['resource_type']).to eq(shareable[:resource_type])
      expect(attributes['resource_id']).to eq(shareable[:resource_id])
      expect(attributes['allow_listing']).to eq(shareable[:allow_listing])
      expect(attributes['created_by_id']).to eq(shareable[:created_by_id])
      expect(attributes['public_uid']).to eq(shareable[:public_uid])
      expect(to_date_string(attributes['expires_at'])).to eq(to_date_string(shareable[:expires_at]))
      expect(to_date_string(attributes['created_at'])).to eq(to_date_string(shareable[:created_at]))
      expect(to_date_string(attributes['updated_at'])).to eq(to_date_string(shareable[:updated_at]))
    end
  end
end
