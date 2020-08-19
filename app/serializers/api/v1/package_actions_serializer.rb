module Api::V1
  class PackageActionsSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :source_id, :source_type, :description, :created_at,
      :location_id, :user_id, :quantity, :action, :item_id, :package_id

    has_one :user, serializer: UserSerializer

    def item_id
      object.package_id
    end

    alias package_id item_id
  end
end
