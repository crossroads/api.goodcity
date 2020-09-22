require 'rails_helper'

describe Api::V2::RoleSerializer do

  let(:role)              { create :role, name: 'hello', level: 42 }
  let(:json)              { Api::V2::RoleSerializer.new(role).as_json }
  let(:attributes)        { json['data']['attributes'] }
  let(:relationships)     { json['data']['relationships'] }
  let(:included_records)  { json['included'] }

  describe "Default" do
    describe "attributes" do
      let(:expected_attributes) {[
        :level,
        :name
      ]}

      it { expect(attributes.keys.map(&:to_sym)).to match_array(expected_attributes) }

      it "includes the correct attributes" do
        expected_attributes.each { |attr| expect(attributes[attr.to_s]).to eql(role[attr]) }
      end
    end
  end
end
