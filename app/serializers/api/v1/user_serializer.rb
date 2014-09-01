module Api::V1

  class UserSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :first_name, :last_name, :created_at, :updated_at

    has_many :offers, serializer: OfferSerializer
  end

end
