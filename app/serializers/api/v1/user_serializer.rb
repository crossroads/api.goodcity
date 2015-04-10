module Api::V1

  class UserSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :first_name, :last_name, :permission_id, :mobile,
      :created_at

    has_one :image, serializer: ImageSerializer
    has_one :address, serializer: AddressSerializer

    def mobile__sql
      "(select users.mobile FROM permissions where permissions.id = #{current_user.permission_id || -1})"
    end
  end

end
