module Api::V1
  class LookupSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :name, :value, :label_en, :label_zh_tw
  end
end
