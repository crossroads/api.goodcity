class ApplicationSerializer < ActiveModel::Serializer

  protected
    def time_zone_query
      "::timestamp without time zone AT TIME ZONE 'UTC' "
    end

    def current_language
      I18n.locale.to_s.underscore
    end
end

