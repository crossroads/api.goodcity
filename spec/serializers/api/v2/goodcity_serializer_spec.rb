require 'rails_helper'

context Api::V2::GoodcitySerializer do
  SERIALIZER_DEFAULT_OPTS = {}

  describe 'String options parsing' do
    let(:model) { :user }

    describe "#parse_include_paths" do
      it "generates fast_jsonapi options based on an include string" do
        {
          "*"                           => { include: [], fields: {:user=>[:id, :first_name, :last_name, :mobile, :title, :created_at, :updated_at, :last_connected, :last_disconnected, :email, :is_email_verified, :is_mobile_verified, :disabled, :preferred_language, :roles]}},
          "first_name,last_name"        => { include: [], fields: { user: [:first_name, :last_name] } },
          "first_name,last_name,roles"  => { include: [], fields: { user: [:first_name, :last_name, :roles] } },
          "{first_name,last_name}"      => { include: [], fields: { user: [:first_name, :last_name] } },
          "first_name,roles.*"          => {:include=>[:roles], :fields=>{:user=>[:first_name, :roles], :role=>[:name, :level]}},
          "roles.*"                     => {:include=>[:roles], :fields=>{:user=>[:roles], :role=>[:name, :level]}},
          "{roles}.*"                   => {:include=>[:roles], :fields=>{:user=>[:roles], :role=>[:name, :level]}}
        }.each do |input, expected_res|
          expect(Api::V2::GoodcitySerializer.parse_include_paths(model, input)).to eq(expected_res)
        end
      end

      describe "whitelist" do
        it "removes relationships if they are not present in the whitelist" do
          whitelist = { users: [:first_name, :last_name] }
          serializer_options = Api::V2::GoodcitySerializer.parse_include_paths(model, 'roles.*,', { whitelist: whitelist })
          expect(serializer_options[:include]).not_to include('roles')
        end

        it "removes fields if they are not present in the whitelist" do
          whitelist = { users: [:first_name, :last_name] }
          serializer_options = Api::V2::GoodcitySerializer.parse_include_paths(model, '*', { whitelist: whitelist })
          expect(serializer_options[:include]).to eq([])
          expect(serializer_options[:fields][:user]).to eq([:first_name, :last_name])
        end

        it "removes fields of relationships if they are not present in the whitelist" do
          whitelist = { roles: [:name], users: [:first_name, :last_name] }
          serializer_options = Api::V2::GoodcitySerializer.parse_include_paths(model, 'roles.name,roles.level,first_name,mobile', { whitelist: whitelist })
          expect(serializer_options[:include]).to eq([:roles])
          expect(serializer_options[:fields][:user]).to eq([:first_name]) # mobile was removed
          expect(serializer_options[:fields][:role]).to eq([:name]) # level was removed
        end
      end
    end

    describe "#build_paths" do
      it 'generates all the different path possibilities' do
        {
          nil => [],
          "" => [],
          ",,," => [],
          "user,roles" => [['user'], ['roles']],
          "{user,roles}" => [['user'], ['roles']],
          "user.first_name,roles.{name,level}" => [['user', 'first_name'], ['roles', 'name'], ['roles', 'level']],
          "user.{offers,orders}.code" => [['user', 'offers', 'code'], ['user', 'orders', 'code']],
          "user.{offers,orders}.{code}" => [['user', 'offers', 'code'], ['user', 'orders', 'code']],
          "roles,user.{offers,orders}.*" => [['roles'], ['user', 'offers', '*'], ['user', 'orders', '*']],
          "user.{offers,orders}.{code,desc}" => [["user", "offers", "code"], ["user", "offers", "desc"], ["user", "orders", "code"], ["user", "orders", "desc"]],
        }.each do |input, expected_res|
          expect(Api::V2::GoodcitySerializer.build_paths(input)).to eq(expected_res)
        end
      end
    end
  end
end
