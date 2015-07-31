module ApplicationHeaders

  def set_admin_app_header
    request.headers['X-GOODCITY-APP-NAME'] = 'admin.goodcity' if request.headers
  end

  def set_donor_app_header
    request.headers['X-GOODCITY-APP-NAME'] = 'app.goodcity' if request.headers
  end

end
