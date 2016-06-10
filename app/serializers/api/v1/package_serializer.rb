module Api::V1

  class PackageSerializer < ApplicationSerializer
    embed :ids, include: true

    has_one :package_type, serializer: PackageTypeSerializer

    attributes :id, :quantity, :length, :width, :height, :notes, :location_id,
      :item_id, :state, :received_at, :rejected_at, :inventory_number,
      :created_at, :updated_at, :package_type_id, :image_id, :offer_id,
      :designation_name, :grade, :donor_condition_id,
      :designation_id, :sent_on

    def designation_id
      object.stockit_designation_id
    end

    def designation_id__sql
      "stockit_designation_id"
    end

    def sent_on
      object.stockit_sent_on
    end

    def sent_on__sql
      "stockit_sent_on"
    end
  end

end
