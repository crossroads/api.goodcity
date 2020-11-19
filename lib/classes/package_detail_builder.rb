class PackageDetailBuilder
  attr_reader :detail_type, :detail_params, :detail_class

  PERMITTED_DETAIL_TYPES = %w[computer electrical computer_accessory medical].freeze
  REJECT_ATTRIBUTES = %w[id comp_test_status test_status frequency voltage].freeze

  def initialize(params)
    @detail_params = params["detail_attributes"]
    @detail_type = params["detail_type"]
    @detail_class = @detail_type&.classify&.safe_constantize
  end

  def build_or_update_record
    klass = detail_class if build_or_update_record?
    return unless klass
    detail_record = klass.find_by(stockit_id: detail_params["id"]) if stockit_id_present?
    if detail_record
      detail_record.assign_attributes(detail_attributes)
      detail_record.save && detail_record
    else
      klass&.new(detail_attributes)
    end
  end

  private

  def stockit_id_present?
    detail_params && detail_params["id"]
  end

  def build_or_update_record?
    PERMITTED_DETAIL_TYPES.include?(detail_type.underscore)
  end

  def detail_attributes
    # rejecting some parameters because our API tables does not have these columns. But we
    # require these params for mapping of parameters for stockit to GC sync,
    # as stockit sends "test_status" and not test_status_id we have to fetch lookup_id for
    # same and assign it to params hash for mapping stockit values to lookup ids on GC
    detail_params["stockit_id"] = detail_params["id"] if stockit_id_present?
    params = detail_params&.except(*REJECT_ATTRIBUTES) || {}
    params
  end
end
