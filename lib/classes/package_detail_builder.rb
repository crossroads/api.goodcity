class PackageDetailBuilder
  attr_reader :detail_type, :detail_params

  def initialize(params, request_from_stockit)
    @detail_params = params["detail_attributes"]
    @detail_type = params["detail_type"]
    @request_from_stockit = request_from_stockit
  end


  def build_detail
    return unless %w[computer electrical computer_accessory].include?(detail_type)
    klass = detail_type.classify.safe_constantize
    params = detail_params_without_some_params.merge(lookup_ids_hash)
    klass&.new(params)
  end

  private

  def detail_params_without_some_params
    return {} unless detail_params
    detail_params.except("id", "comp_test_status", "test_status", "frequency", "voltage")
  end

  # mapping stockit request and setting id for
  def lookup_ids_hash
    return {} unless @request_from_stockit
    ["comp_test_status, ""test_status", "frequency", "voltage"].each_with_object({}) do |item, hash|
      if (key = detail_params[item].presence)
        name = "electrical_#{item}" unless (item === "comp_test_status")
        hash["#{item}_id"] = Lookup.find_by(name: name, key: key)&.id
      end
    end
  end
end
