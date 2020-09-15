require 'rails_helper'

describe Api::V2::UserRoleSerializer do

  let(:user)              { create :user, :with_order_administrator_role }
  let(:user_role)         { user.user_roles.first }
  let(:role)              { user_role.role }
  let(:json)              { Api::V2::UserRoleSerializer.new(user_role).as_json }
  let(:attributes)        { json['data']['attributes'] }
  let(:relationships)     { json['data']['relationships'] }
  let(:included_records)  { json['included'] }

  describe "Default" do
    describe "attributes" do
      EXPECTED_ATTRIBUTES = [
        :created_at,
        :updated_at
      ]

      it { expect(attributes.keys.map(&:to_sym)).to match_array(EXPECTED_ATTRIBUTES) }

      EXPECTED_ATTRIBUTES.each do |attr|
        it "includes the #{attr} attribute" do
          if user_role[attr].is_a?(Time)
            expect(Time.parse(attributes[attr.to_s]).to_s).to eql(user_role[attr].to_s)
          else
            expect(attributes[attr.to_s]).to eql(user_role[attr])
          end
        end
      end
    end

    describe "relationships" do
      it "don't include the body of any relationship" do
        expect(included_records).to eq(nil)
        expect(relationships).not_to be_nil
      end

      it "includes the role id" do
        expect(relationships['role']['data']).to eq({ "id" => role.id.to_s, "type" => "role" })
      end

      it "includes the user id" do
        expect(relationships['user']['data']).to eq({ "id" => user.id.to_s, "type" => "user" })
      end
    end
  end
end
