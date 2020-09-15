require 'rails_helper'

context Api::V2::GoodcitySerializer do

  describe 'String options parsing' do
    let(:model) { :user }

    describe "#parse_include_paths" do
      it "generates fast_jsonapi options based on an include string" do
        {
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
