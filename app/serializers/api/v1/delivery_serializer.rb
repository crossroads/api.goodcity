module Api::V1
  class DeliverySerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :start, :finish, :offer_id, :delivery_type

    has_one :contact, serializer: ContactSerializer
    has_one :schedule, serializer: ScheduleSerializer
    has_one :gogovan_order, serializer: GogovanOrderSerializer

    # include if nil or false.
    # Used to exclude contacts in OfferSummarySerializer
    def include_contact?
      !(@options[:summarize] == true)
    end
  end
end
