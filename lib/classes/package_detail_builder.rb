class PackageDetailBuilder
  attr_reader :detail_type, :detail_params

  def initialize(params)
    @detail_params = params["detail_attributes"]
    @detail_type = params["detail_type"]
  end

  def build_detail
    return unless %w[computer electrical computer_accessory].include?(detail_type)
    klass = detail_type.classify.safe_constantize
    klass&.new(detail_params_without_id)
  end

  def detail_params_without_id
    detail_params.except(detail_params["id"])
  end
end
