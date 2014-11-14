module Api::V1

  # Don't forget underlying models should have 'include I18nCacheKey' if applicable
  # Don't use this on objects that have a 'User' perspective e.g. messages
  class CachingSerializer < ActiveModel::Serializer
    cached
    delegate :cache_key, to: :object
  end

end
