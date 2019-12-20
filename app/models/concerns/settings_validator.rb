class SettingsValidator < ActiveModel::Validator
  def initialize(options)
    super
    @keys = options[:settings][:keys]
  end

  def validate(record)
    error_message = ""
    @keys.each do |key|
      error_message_key = "activerecord.errors.models.#{record.class.name.underscore}.#{key}"
      error_message += " #{I18n.t(error_message_key)}" unless action_allowed?(key)
    end
    record.errors.add(:base, error_message)
  end

  def action_allowed?(key)
    GoodcitySetting.where("key ILIKE ?", "%#{key}%").last&.value&.eql?("true")
  end
end
