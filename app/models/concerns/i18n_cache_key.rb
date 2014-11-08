#
# Make ActiveRecord::cache_key I18n aware
#
module I18nCacheKey

  extend ActiveSupport::Concern

  def cache_key
    super << "-#{I18n.locale}"
  end

end
