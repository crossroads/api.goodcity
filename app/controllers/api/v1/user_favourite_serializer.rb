module Api::V1
  class UserFavouriteSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :favourite_type, :favourite_id, :user_id, :persistent
  end
end
