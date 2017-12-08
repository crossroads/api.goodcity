module Api::V1
  class OrganisationSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :name_en, :name_zh_tw, :description_en, :description_zh_tw, :registration,
      :website, :organisation_type_id, :district_id, :country_id, :order_ids, :created_at,
      :updated_at

    has_many :organisations_users, serializer: OrganisationsUserSerializer
    has_many :orders, serializer: OrderSerializer

    def order_ids
    end

    def order_ids__sql
      'order_ids'
    end
  end
end
