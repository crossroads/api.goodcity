require 'rails_helper'

describe Api::V2::RoleSerializer do

  let(:role)              { create :role, name: 'hello', level: 42 }
  let(:json)              { Api::V2::RoleSerializer.new(role).as_json }
  let(:attributes)        { json['data']['attributes'] }
  let(:relationships)     { json['data']['relationships'] }
  let(:included_records)  { json['included'] }

  describe "Default" do
    describe "attributes" do
      EXPECTED_ATTRIBUTES = [
        :level,
        :name
      ]

      it { expect(attributes.keys.map(&:to_sym)).to match_array(EXPECTED_ATTRIBUTES) }

      EXPECTED_ATTRIBUTES.each do |attr|
        it "includes the #{attr} attribute" do
          expect(attributes[attr.to_s]).to eql(role[attr])
        end
      end
    end
  end
end
