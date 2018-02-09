module Api::V1
  class PurposeSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :name_en, :name_zh_tw
  end
end
