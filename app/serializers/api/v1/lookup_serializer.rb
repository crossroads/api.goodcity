module Api
  module V1
    class LookupSerializer < ApplicationSerializer
      embed :ids, include: true
      attributes :id, :name, :key, :label_en, :label_zh_tw
    end
  end
end
