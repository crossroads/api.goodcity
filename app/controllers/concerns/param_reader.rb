module ParamReader
  extend ActiveSupport::Concern

  def bool_param(key, default_val = false)
    return default_val unless params.include?(key)
    params[key].to_s == "true"
  end

  def array_param(key)
    params.fetch(key, "").strip.split(",")
  end
end
