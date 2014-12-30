module Api::V1

  class UserSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :first_name, :last_name, :permission_id

    has_one :image, serializer: ImageSerializer
  end

end
