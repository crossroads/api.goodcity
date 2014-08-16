#
# A simple cache implementation for taxonomy lists
# Generates json for all items and writes to cache
# Useful for taxonomy lists where all users are allowed to see all objects and attributes
# Optionally, if the model has a 'with_eager_load' scope, use that to generate the objects to cache
#
module CacheableJson

  extend ActiveSupport::Concern

  included do
    after_save -> { Rails.cache.delete(self.class.cache_key) }
  end

  # Methods defined here are going to extend the class, not the instance
  module ClassMethods

    def cache_key
      "#{name.underscore}:#{I18n.locale}"
    end

    # Save the json representation to cache (operates on all objects)
    def cache_json
      records = try(:with_eager_load) || all
      objects = ActiveModel::ArraySerializer.new(records, each_serializer: "Api::V1::#{name}Serializer".constantize).to_json
      Rails.cache.write(cache_key, objects)
      objects
    end

    # Return the cached json or generate it if needed
    def cached_json
      Rails.cache.fetch(cache_key) || cache_json
    end

  end

end
