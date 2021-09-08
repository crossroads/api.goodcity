class PackageDetailBuilder
  attr_reader :detail_type, :detail_attributes, :detail_class, :detail_id

  PERMITTED_DETAIL_TYPES = %w[computer electrical computer_accessory medical].freeze

  def initialize(params)
    @detail_attributes = params["detail_attributes"]
    @detail_id = params["detail_id"]
    @detail_type = params["detail_type"]
    @detail_class = @detail_type&.classify&.safe_constantize
  end

  def build_or_update_record
    klass = detail_class if build_or_update_record?
    return unless klass

    detail_record = klass.find_by(id: detail_id) if detail_id.present?
    return detail_record.save && detail_record if detail_record

    klass&.new(detail_attributes)
  end

  private

  def build_or_update_record?
    PERMITTED_DETAIL_TYPES.include?(detail_type.underscore)
  end
end
