module AppMatcher
  extend ActiveSupport::Concern

  def is_admin_app
    app_name == ADMIN_APP
  end

  def is_stock_app
    @app_name == STOCK_APP
  end

  def is_stockit_request
    @app_name == STOCKIT_APP
  end

  def is_browse_app
    @app_name == BROWSE_APP
  end

  protected

  def app_name
    request.headers['X-GOODCITY-APP-NAME'] || meta_info["appName"]
  end

  def meta_info
    meta = request.headers["X-META"].try(:split, "|")
    meta ? Hash[*meta.flat_map{|a| a.split(":")}] : {}
  end
end
