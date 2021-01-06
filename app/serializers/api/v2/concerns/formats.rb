module Api::V2::Concerns
  module Formats
    extend ActiveSupport::Concern

    included do

      class << self 
        def scoped_formats
          @@scoped_formats ||= []
        end

        alias_method :jsonapi_attributes, :attributes

        #
        # Override the attribute method to support contexts
        #
        # @param [<Type>] *attributes_list <description>
        # @param [<Type>] &block <description>
        #
        # @return [<Type>] <description>
        #
        def attributes(*attributes_list, &block)
          formats = [*scoped_formats]

          if formats.length.positive?
            opts = attributes_list.last
            unless opts.is_a?(Hash)
              opts = {}
              attributes_list << opts
            end

            cond = opts[:if]
            opts[:if] = Proc.new do |_, params = {}|
              next false if cond.present? && !cond.call(_, params)
              render_formats = [params[:format]].compact.flatten

              formats.all? { |f| f.in?(render_formats) }
            end
          end

          jsonapi_attributes(*attributes_list, &block)
        end

        def format(fmt)
          scoped_formats.push(fmt)
          yield
          scoped_formats.pop
        end

        alias_method :attribute, :attributes
      end
    end
  end
end
