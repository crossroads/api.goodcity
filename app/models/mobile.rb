class Mobile

  include ActiveModel::Validations

  attr_accessor :mobile

  HongKongMobileRegExp = /\A\+852[569]\d{7}\z/
  validates :mobile, format: { with: HongKongMobileRegExp, message: I18n.t('activerecord.errors.models.user.attributes.mobile.invalid') }

  def initialize(mobile)
    @mobile = mobile
  end

end
