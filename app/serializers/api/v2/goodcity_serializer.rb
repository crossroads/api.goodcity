module Api::V2
  class GoodcitySerializer < Serializer

    def initialize(resources, opts = {})
      options = opts

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
        [
          serializer.try(:attributes_to_serialize).try(:keys)     || [],
          serializer.try(:relationships_to_serialize).try(:keys)  || []
        ].flatten
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
            res += matrix.first.map { |i| [i] }                                     if matrix.length == 1
            res
          end
      end

      #
      # Given a certain configuration and a whitelist, removes all the relationships and fields which are not allowed
      #
      # @param [Hash] config the json serializer config
      # @param [Hash] whitelist a map of model to array of fields, describing what is permitted per model
      #
      # @return [Hash] the whitelisted configuration
      #
      def apply_config_whitelist(config, whitelist)
        return config unless whitelist

        models    = whitelist.keys
        included  = (config.dig(:include) || []).select { |m| m.in?(models) }

        fields = models.reduce({}) do |res, model|
          model_singular  = model.to_s.singularize.to_sym
          selected_fields = config.dig(:fields, model_singular)

          next res unless selected_fields.present?

          allowed = whitelist[model] || []
          res[model_singular] = selected_fields if allowed == '*'
          res[model_singular] = selected_fields.select { |f| f.in?(allowed) } if allowed.is_a?(Array) if allowed.is_a?(Array)
          res[model_singular] ||= []
          res
        end

        { include: included, fields: fields }
      end

      #
      # Generates FastJSON Serializer options based on a query string
      #
      # e.g /users?include=first_name,last_name,roles.*,orders.code
      #
      # @param [Symbol] root_model the root serializer model e.g :user
      # @param [String] str the include string to parse
      # @param [Hash] opts options
      # @param [Hash] opts.whitelist a map of model to array of fields, describing what is permitted per model
      #
      # @return [Hash] The fast_jsonapi options
      #
      def parse_include_paths(root_model, str, opts = {})      
        return apply_config_whitelist({}, opts[:whitelist]) if str.blank?

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

        apply_config_whitelist({
          include:  includes.uniq.each(&:to_sym),
          fields:   fields.transform_values { |arr| arr.flatten.uniq }
        }, opts[:whitelist])
      end
    end
  end
end
