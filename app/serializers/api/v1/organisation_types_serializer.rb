# frozen_string_literal: true

module Api
  module V1
    class OrganisationTypesSerializer < ApplicationSerializer
      embed :ids, include: true

      attributes :id, :name, :category

      def name__sql
        "name_#{current_language}"
      end

      def category__sql
        "category_#{current_language}"
      end
    end
  end
end
