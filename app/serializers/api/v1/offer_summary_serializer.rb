module Api::V1
  class OfferSummarySerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :state, :created_at, :inactive_at,
      :updated_at, :submitted_at, :reviewed_at, :review_completed_at,
      :received_at, :cancelled_at, :start_receiving_at,
      :submitted_items_count, :accepted_items_count, :rejected_items_count,
      :expecting_packages_count, :missing_packages_count, :received_packages_count

    has_one  :closed_by, serializer: UserSummarySerializer, root: :user
    has_one  :created_by, serializer: UserSummarySerializer, root: :user
    has_one  :reviewed_by, serializer: UserSummarySerializer, root: :user
    has_one  :received_by, serializer: UserSummarySerializer, root: :user
    has_many :images, serializer: ImageSerializer, root: :images
    has_one  :delivery, serializer: DeliverySerializer, root: :delivery

    def submitted_items_count
      object.submitted_items.size
    end

    def submitted_items_count__sql
      "(SELECT COUNT(*) FROM items i WHERE i.offer_id = offers.id AND i.state = 'submitted')"
    end

    def accepted_items_count
      object.accepted_items.size
    end

    def accepted_items_count__sql
      "(SELECT COUNT(*) FROM items i WHERE i.offer_id = offers.id AND i.state = 'accepted')"
    end
    
    def rejected_items_count
      object.rejected_items.size
    end

    def rejected_items_count__sql
      "(SELECT COUNT(*) FROM items i WHERE i.offer_id = offers.id AND i.state = 'rejected')"
    end

    def expecting_packages_count
      object.expecting_packages.size
    end

    # offers.id is the ID of the offer in the PES parent query
    def expecting_packages_count__sql
      "(SELECT COUNT(*) FROM packages LEFT JOIN items ON items.id = packages.item_id LEFT JOIN offers o ON o.id = items.offer_id WHERE offers.id = o.id AND packages.state = 'expecting')"
    end

    def missing_packages_count
      object.missing_packages.size
    end

    def missing_packages_count__sql
      "(SELECT COUNT(*) FROM packages LEFT JOIN items ON items.id = packages.item_id LEFT JOIN offers o ON o.id = items.offer_id WHERE offers.id = o.id AND packages.state = 'missing')"
    end

    def received_packages_count
      object.received_packages.size
    end

    def received_packages_count__sql
      "(SELECT COUNT(*) FROM packages LEFT JOIN items ON items.id = packages.item_id LEFT JOIN offers o ON o.id = items.offer_id WHERE offers.id = o.id AND packages.state = 'received')"
    end

  end
end
