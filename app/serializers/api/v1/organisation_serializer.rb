module Api::V1
  class OrganisationSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :name_en, :name_zh_tw, :description_en, :description_zh_tw, :registration,
      :website, :organisation_type_id, :district_id, :country_id, :created_at,
      :updated_at, :orders_count

    has_many :organisations_users, serializer: OrganisationsUserSerializer

    def orders_count
      object.orders.size
    end

    def orders_count__sql
      "(SELECT COUNT(*) FROM orders o WHERE o.organisation_id = orders.id"
    end
  end
end
