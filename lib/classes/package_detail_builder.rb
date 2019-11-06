class PackageDetailBuilder
  FIXED_DETAIL_ATTRIBUTES = %w[comp_test_status test_status frequency voltage].freeze
  attr_reader :detail_type, :detail_params

  def initialize(params, request_from_stockit)
    @detail_params = params["detail_attributes"]
    @detail_type = params["detail_type"]
    @request_from_stockit = request_from_stockit
  end

  def build_detail
    return unless %w[computer electrical computer_accessory].include?(detail_type)
    klass = detail_type.classify.safe_constantize
    klass&.new(detail_attributes)
  end

  private

  def detail_attributes
    # rejecting some parameters because our API tables does not have these columns. But we
    # require these params for mapping of parameters for stockit to GC sync,
    # as stockit sends "test_status" and not test_status_id we have to fetch lookup_id for
    # same and assign it to params hash for mapping stockit values to lookup ids on GC
    detail_params["stockit_id"] = detail_params["id"] if detail_params && detail_params["id"]
    params = detail_params&.except("id", "comp_test_status", "test_status", "frequency", "voltage") || {}
    # map stockit values to lookup ids if request from stockit
    lookup_hash = map_lookup_id if @request_from_stockit
    lookup_hash ? params.merge(lookup_hash) : params
  end

  def map_lookup_id
    FIXED_DETAIL_ATTRIBUTES.each_with_object({}) do |item, hash|
      if (key = detail_params[item].presence)
        name = "electrical_#{item}" unless (item == "comp_test_status")
        hash["#{item}_id"] = Lookup.find_by(name: name, key: key)&.id
      end
    end
  end
end
