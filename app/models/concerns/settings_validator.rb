class SettingsValidator < ActiveModel::Validator
  def initialize(options)
    super
    @keys = options[:settings][:keys]
  end

  # Create setting with app_name in the beggining of the key to identify. eg 'stock.abc'
  def validate(record)
    error_messages = []
    @keys.each do |key|
      unless GoodcitySetting.enabled?(key)
        error_message_key = "activerecord.errors.models.#{record.class.name.underscore}.#{key.split('.').last}"
        error_messages << I18n.t(error_message_key)
      end
    end
    record.errors.add(:base, error_messages.join(" ")) unless error_messages.empty?
  end
end
