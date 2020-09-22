require 'rails_helper'

describe Api::V2::UserSerializer do

  let(:user)              { create :user, :charity, :with_order_administrator_role }
  let(:role)              { user.roles.first }
  let(:empty_opts)        { {} }
  let(:json)              { Api::V2::UserSerializer.new(user, opts).as_json }
  let(:attributes)        { json['data']['attributes'] }
  let(:relationships)     { json['data']['relationships'] }
  let(:included_records)  { json['included'] }

  describe "Default" do
    let(:opts) { empty_opts }

    describe "attributes" do
      [
        :id,
        :first_name,
        :last_name,
        :mobile,
        :title,
        :email,
        :is_email_verified,
        :is_mobile_verified,
        :disabled,
        :preferred_language
      ].each do |attr|
        it "includes the #{attr} attribute" do
          expect(attributes[attr.to_s]).to eql(user[attr])
        end
      end

      context 'dates' do
        [
          :created_at,
          :updated_at,
          :last_connected,
          :last_disconnected
        ].each do |attr|
          it "includes the #{attr} date attribute" do
            expect(Time.parse(attributes[attr.to_s]).to_s).to eql(user[attr].to_s)
          end
        end
      end
    end

    describe "relationships" do
      it "doesn't include the body of any relationship" do
        expect(included_records).to eq(nil)
        expect(relationships).not_to be_nil
      end

      it "includes role ids" do
        expect(relationships).not_to be_nil
        expect(user.roles.length).to eq(1)
        expect(relationships['roles']['data'].length).to eq(user.roles.length)
        expect(relationships['roles']['data'][0]).to eq({ "id" => user.roles.first.id.to_s, "type" => "role" })
      end
    end
  end

  describe "Custom configs" do
    
    describe "including body of relationships" do
      let(:opts) { Api::V2::GoodcitySerializer.parse_include_paths(:user, 'roles.*') }

      it "builds the correct config from a string" do
        expect(opts).to eq({:include=>[:roles], :fields=>{:user=>[:roles], :role=>[:name, :level]}})
      end

      it "includes the body of the specified relationships" do
        expect(included_records).not_to be_nil
        expect(included_records).to eq([{
          "id"        =>  role.id.to_s,
          "type"      =>  "role",
          "attributes"=>  { "name" => role.name, "level" => role.level }
        }])
      end
    end

    describe "selecting specific attributes" do
      let(:opts) { Api::V2::GoodcitySerializer.parse_include_paths(:user, 'first_name,last_name') }

      it "builds the correct config from a string" do
        expect(opts).to eq({:include=>[], :fields=>{:user=>[:first_name, :last_name]}})
      end

      it "only includes the specified attributes" do
        expect(attributes.keys).to eq(['first_name', 'last_name'])
      end
    end
  end
end
