class ApplicationSerializer < ActiveModel::Serializer
  protected
    def current_language
      I18n.locale.to_s.underscore
    end
end

