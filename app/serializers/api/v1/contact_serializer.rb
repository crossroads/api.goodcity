module Api::V1

  class ContactSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :name, :mobile
  end

end
