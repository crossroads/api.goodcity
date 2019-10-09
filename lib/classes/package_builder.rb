class PackageBuilder
  attr_reader :params, :detail_type, :detail_params

  def initialize(params, detail_type)
    @params = params
    @detail_type = detail_type
    @detail_params = params["detail_attributes"]
  end

  def create_package_detail
    @detail = detail_type.classify.safe_constantize.new(detail_params)
    return return_success.merge!("detail" => @detail) if @detail.save

    fail_with_error(@detail.errors)
  end

  private

  def fail_with_error(errors)
    errors = errors.full_messages.join(". ") if errors.respond_to?(:full_messages)
    {"result" => false, "errors" => errors}
  end

  def return_success
    {"result" => true}
  end
end
