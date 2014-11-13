module Api::V1

  class UserSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :first_name, :last_name

  end

end
