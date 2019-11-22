require 'csv'
require 'goodcity/compare/base'

module Goodcity
  class Compare

    class Items < Base

      def self.run
        new(table: "items").run
      end

      private

      # handle case where X numbers are stored differently
      def diff(a,b)
        a['inventory_number'].gsub!(/^X/, '')
        b['inventory_number'].gsub!(/^X/, '')
        a.merge(b) { |k, v1, v2| v1 == v2 ? :equal : [v1, v2] }.
          reject { |_, v| v == :equal }
      end

    end

  end
end
