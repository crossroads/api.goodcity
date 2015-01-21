module Api::V1

  class OfferSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :language, :state, :origin, :stairs, :parking,
      :estimated_size, :notes, :created_by_id, :created_at,
      :updated_at, :submitted_at, :reviewed_at, :gogovan_transport_id,
      :crossroads_transport_id, :crossroads_truck_cost

    has_many :items, serializer: ItemSerializer
    has_many :messages, serializer: MessageSerializer
    has_one  :created_by, serializer: UserSerializer, root: :user
    has_one  :reviewed_by, serializer: UserSerializer, root: :user
    has_one  :delivery, serializer: DeliverySerializer
    has_one  :gogovan_transport, serializer: GogovanTransportSerializer
    has_one  :crossroads_transport, serializer: CrossroadsTransportSerializer

    def crossroads_truck_cost
      transport = object.crossroads_transport
      cost = 0
      if transport
        value = transport.try(:name).split(' ').first.to_r.to_f
        cost = (CROSSROADS_TRUCK_COST.to_f * value).ceil
      end
      cost
    end

    def crossroads_truck_cost__sql
      has_transport = "select name_#{I18n.locale} from crossroads_transports ct
        where ct.id = offers.crossroads_transport_id AND
        ct.name_en <> 'Disable'"

      cost_query =
        "select CEILING(
         cast((substring(name_#{I18n.locale} from 1 for 1)) as double precision) /
         cast((substring(name_#{I18n.locale} from 3 for 1)) as double precision) * #{CROSSROADS_TRUCK_COST.to_f})
         from crossroads_transports ct
         where ct.id = offers.crossroads_transport_id AND ct.name_en <> 'Disable'"

      "CASE
         WHEN EXISTS(#{has_transport})
         THEN (#{cost_query})
         ELSE '0'
       END"
    end
  end
end
