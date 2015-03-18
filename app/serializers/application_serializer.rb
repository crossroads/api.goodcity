class ApplicationSerializer < ActiveModel::Serializer

  protected
    def time_zone_query
      "::timestamp with time zone AT TIME ZONE
        '#{Time.zone.tzinfo.identifier}' "
    end

    def current_language
      I18n.locale.to_s.underscore
    end
end

