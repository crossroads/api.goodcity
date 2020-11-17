module Api
  module V1
    class CannedResponseSerializer < ApplicationSerializer
      embed :ids, include: true
      attributes :id, :name_en, :name_zh_tw, :content_en, :content_zh_tw
    end
  end
end
