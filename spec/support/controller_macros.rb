module ControllerMacros
  def set_locale(change_to_language, default_language='en')
    I18n.locale = default_language
    request.env['HTTP_ACCEPT_LANGUAGE'] = change_to_language
    HttpAcceptLanguage::Middleware.new(lambda {|env| env }).call(request.env)
  end
end
