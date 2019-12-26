module AppMatcher
  extend ActiveSupport::Concern

  # Identifies which app is currently making the controller request

  def is_admin_app?
    app_name == ADMIN_APP
  end

  def is_stock_app?
    app_name == STOCK_APP
  end

  def is_browse_app?
    app_name == BROWSE_APP
  end

  def is_stockit_request?
    app_name == STOCKIT_APP
  end

  # return sanitized app name from request header
  # return 'app', 'admin', 'stock', 'browse', 'stockit'

  def app_name
    @request_app_name ||= begin
      request_app_name = request.headers['X-GOODCITY-APP-NAME'] || meta_info["appName"] || ''
      request_app_name.gsub!('.goodcity', '')
      APP_NAMES.include?(request_app_name) ? request_app_name : nil
    end
  end

  protected

  def meta_info
    meta = request.headers["X-META"].try(:split, "|")
    meta ? Hash[*meta.flat_map{|a| a.split(":")}] : {}
  end

end
