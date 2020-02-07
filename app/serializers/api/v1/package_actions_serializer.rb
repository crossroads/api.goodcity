module Api::V1
  class PackageActionsSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :source_id, :source_type, :description, :created_at,
      :location_id, :user_id, :quantity, :action, :item_id, :package_id

    alias_method :item_id, :package_id

    def item_id__sql
      "package_id"
    end
  end
end