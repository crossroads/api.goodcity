module Api
  module V1
    class CannedResponseSerializer < ApplicationSerializer
      embed :ids, include: true
      attributes :id, :content_en, :content_zh_tw, :content, :name, :name_en

      def name
        object.try("name_#{current_language}".to_sym)
      end

      def content
        object.try("content_#{current_language}".to_sym)
      end
    end
  end
end
