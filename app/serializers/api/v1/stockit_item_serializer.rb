module Api::V1

  class StockitItemSerializer < ApplicationSerializer
    embed :ids, include: true

    has_one :package_type, serializer: PackageTypeSerializer, root: :code
    has_one :location, serializer: LocationSerializer
    has_one :stockit_designation, serializer: Api::V1::StockitDesignationSerializer, root: :designation, include_items: false

    attributes :id, :quantity, :length, :width, :height, :notes, :location_id,
      :inventory_number, :created_at, :updated_at,
      :designation_name, :designation_id, :sent_on, :code_id

    def include_stockit_designation?
      @options[:include_stockit_designation]
    end

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

    def code_id
      object.package_type_id
    end

    def code_id__sql
      "package_type_id"
    end
  end

end
