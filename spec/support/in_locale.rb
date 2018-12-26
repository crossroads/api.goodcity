module LocaleSwitcher

  def in_locale(locale)
    current_locale = I18n.locale
    I18n.locale = locale
    yield
    I18n.locale = current_locale
  end
  
end