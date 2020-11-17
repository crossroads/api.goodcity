class CannedResponse < ApplicationRecord
  include CacheableJson
  include FuzzySearch

  configure_search(
    props: [
      :name_en,
      :name_zh_tw,
      :content_en,
      :content_zh_tw
    ],
    default_tolerance: 0.8
  )
end
