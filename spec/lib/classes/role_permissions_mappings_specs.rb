# frozen_string_literal: true

require 'rails_helper'

describe RolePermissionsMappings do
  describe '.apply' do
    let(:permissions_roles) { generate(:permissions_roles) }

    it 'adds missing roles and permissions' do
      RolePermissionsMappings.apply!
      permissions_roles.each_pair do |role_name, permissions|
        role = Role.find_by(name: role_name)
        permissions.flatten!
        expect(role.permissions.map(&:name)).to match_array(permissions)
      end
    end

    context 'if there are additional permissions for roles' do
      it 'removes additional permissions for roles' do
        RolePermissionsMappings.apply!
        charity = Role.where(name: 'Charity').first_or_create
        charity.permissions << Permission.where(name: 'can_manage_packages_locations').first_or_create
        charity.permissions << Permission.where(name: 'can_check_organisations').first_or_create
        expect { RolePermissionsMappings.apply! }.to change(RolePermission, :count).by(-2)
      end
    end
  end
end
