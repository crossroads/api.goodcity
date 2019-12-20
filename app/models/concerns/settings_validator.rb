class SettingsValidator < ActiveModel::Validator
  def initialize(options)
    super
    @keys = options[:settings][:keys]
  end

  def validate(record)
    error_messages = []
    @keys.each do |key|
      unless action_allowed?(key)
        error_message_key = "activerecord.errors.models.#{record.class.name.underscore}.#{key}"
        error_messages << I18n.t(error_message_key)
      end
    end
    record.errors.add(:base, error_messages.join(" ")) if error_messages.length > 0
  end

  private

  def action_allowed?(key)
    GoodcitySetting.where("key ILIKE ?", "%#{key}%").last&.value&.eql?("true")
  end
end
