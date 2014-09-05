module Api::V1

  class UserSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :first_name, :last_name, :mobile, :full_name, :district

    has_many :permissions, serializer: PermissionSerializer

    def mobile
      object.try(:mobile) && object.mobile.slice!(4..-1)
    end

    def full_name
      object.try(:full_name)
    end

    def district
      object.try(:address).try(:district).try(:name_en)
    end
  end

end
