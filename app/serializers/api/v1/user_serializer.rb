module Api::V1

  class UserSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :first_name, :last_name, :created_at, :updated_at, :mobile

    def mobile
      object.try(:mobile) && object.mobile.slice!(4..-1)
    end
  end

end
