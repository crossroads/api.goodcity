module Api::V2
  class GoodcitySerializer < Serializer

    def initialize(resources, opts = {})
      options = opts.clone

      options[:include] ||= []    # By default, we do not want the body of relationships

      super(resources, options)      
    end


    class << self
      
      def serializer_for(type)
        "Api::V2::#{type.to_s.camelize}Serializer".safe_constantize
      end

      def fields_for(type)
        serializer = serializer_for(type)
        return [] if serializer.blank?
        serializer.attributes_to_serialize.keys
      end

      #
      # Extracts paths out of the include query param
      #
      # e.g "user.first_name,roles.{name,level}" => [['user', 'first_name'], ['roles', 'name'], ['roles', 'level']]
      #
      # @param [String] input_str the input
      #
      # @return [Array<Array>] a list of paths
      #
      def build_paths(input_str)
        return [] if input_str.blank?

        input_str.split(/,\s*(?=[^{}]*(?:\{|$))/)
          .reduce([]) do |res, path_str|
            matrix = path_str
              .split('.')
              .map { |field| field.gsub(/[{}]/, '').split(',') }

            res += Utils::Algo.flatten_matrix(matrix) { |f1,f2|  [f1,f2].flatten }  if matrix.length > 1
            res << matrix.first                                                     if matrix.length == 1
            res
          end
      end

      #
      # Generates FastJSON Serializer options based on a query string
      #
      # e.g /users?include=first_name,last_name,roles.*,orders.code
      #
      # @param [Symbol] root_model the root serializer model e.g :user
      # @param [String] str the include string to parse
      #
      # @return [Hash] The fast_jsonapi options
      #
      def parse_include_paths(root_model, str)
        return {} if str.blank?
      
        fields    = { root_model => [] }
        includes  = []

        add = lambda do |model, field|
          includes << model unless model.eql?(root_model)
          
          key = model.to_s.singularize.to_sym
          fields[key] ||= []
          fields[key] << field.to_sym       if field != '*'
          fields[key] << fields_for(key)    if field == '*'
        end

        build_paths(str).each do |path|
          add.call root_model, path.first
          if path.length > 1
            path.each_with_index do |model, i|
              add.call(model.to_sym, path[i + 1]) if i < path.length - 1
            end
          end
        end

        {
          include:  includes.uniq.each(&:to_sym),
          fields:   fields.transform_values { |arr| arr.flatten.uniq }
        }
      end
    end
  end
end