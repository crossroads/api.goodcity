class PackageBuilder
  attr_reader :params, :detail_type, :detail_params

  def initialize(params, detail_type)
    @params = params
    @detail_type = detail_type
    @detail_params = params["detail_attributes"]
  end

  def create_package_detail
    @detail = detail_type.classify.safe_constantize.create(detail_params)
    @detail
  end
end
