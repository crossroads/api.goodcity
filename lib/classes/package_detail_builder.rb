class PackageDetailBuilder
  attr_reader :detail_params, :detail_type

  def initialize(detail_params, detail_type)
    @detail_params = detail_params
    @detail_type = detail_type
  end

  def create_detail
    params = ActiveSupport::HashWithIndifferentAccess.new(detail_params)
    detail = detail_type.classify.safe_constantize.create(params)
  end
end


