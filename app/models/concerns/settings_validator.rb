class SettingsValidator < ActiveModel::Validator
  @@enabled = true

  def initialize(options)
    super
    @keys = options[:settings][:keys]
  end

  # Create setting with app_name in the beggining of the key to identify. eg 'stock.abc'
  def validate(record)
    return unless @@enabled
    error_messages = []
    @keys.each do |key|
      unless GoodcitySetting.enabled?(key)
        error_message_key = "activerecord.errors.models.#{record.class.name.underscore}.#{key.split('.').last}"
        error_messages << I18n.t(error_message_key)
      end
    end
    record.errors.add(:base, error_messages.join(" ")) unless error_messages.empty?
  end

  class << self
    def bypass
      @@enabled = false
      yield
    ensure
      @@enabled = true
    end
  end
end
