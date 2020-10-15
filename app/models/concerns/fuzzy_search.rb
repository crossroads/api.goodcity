module FuzzySearch
  extend ActiveSupport::Concern

  class_methods do
    attr_reader :search_joins

    #
    # Configuration of fuzzy search
    #
    # @param [Array<Symbol|Hash>] props array of columns to search against
    # @param [float] tolerance the tolerance of the search between 0 and 1 \
    #     0 requires a perfect match and 1 lets any similarity through
    #
    def configure_search(props: [], default_tolerance: 0.9)
      @default_tolerance  = default_tolerance
      @search_config      = normalize_seach_configuration(props)
    end

    def search_configuration
      return @search_config if @search_config.present?

      @schema_based_search_config ||= begin
        props = columns.select { |c| c.type == :string }.map(&:name)
        normalize_seach_configuration(props)
      end
    end

    def normalize_seach_configuration(props)
      props.reduce({}) do |cfg, prop|
        prop_name = prop.is_a?(Symbol) ? prop : prop[:field]
        tolerance = prop.is_a?(Hash)   ? prop[:tolerance] : default_search_tolerance
        cfg[prop_name] = {
          threshold: search_tolerance_to_similarity_threshold(tolerance || default_search_tolerance)
        }
        cfg
      end
    end

    ##
    # Returns the search tolerance factor, a float between 0 and 1
    #
    # @return [float]
    #
    def default_search_tolerance
      @default_tolerance || 0.9
    end

    ##
    # Returns the search similarity factor based on the set tolerance
    #
    # @return [float]
    #
    def search_tolerance_to_similarity_threshold(tolerance)
      1 - tolerance
    end

    ##
    # Returns the columns that are included in the search
    #
    # @return [string[]]
    #
    def search_prop_names
      search_configuration.keys
    end
  end

  included do
    ##
    # Fuzzy search entry point
    #
    # @todo \
    #   - Support join table properties (needed for other models)\
    #   - Potential speed improvements (trigram indexes, using <-> operators)\
    #   - Assess whether order_by has priority issues
    #
    # @param [string] search_text the text to search for
    # @return [ActiveRecord::Relation]
    #
    # Current SQL looks something like this:
    #
    #  SELECT DISTINCT
    #     SIMILARITY(name_en, 'steve'),
    #     SIMILARITY(name_zh_tw, 'steve'),
    #     organisations.*
    #  FROM organisations
    #  WHERE
    #     SIMILARITY(name_en, 'steve') > 0.1 OR
    #     SIMILARITY(name_zh_tw, 'steve') > 0.1
    #  ORDER BY
    #     SIMILARITY(name_en, 'steve') DESC,
    #     SIMILARITY(name_zh_tw, 'steve') DESC
    #
    scope :search, ->(search_text) {
      similarities = search_prop_names.reduce({}) do |sims, f|
        sims[f] = "SIMILARITY(#{f}, '#{search_text}')"
        sims
      end 

      select_list = similarities.values + ["#{table_name}.*"]
      conditions  = similarities.map { |f, s| "#{s} >= #{search_configuration[f][:threshold]}" }
      ordering    = similarities.values.map { |s| "#{s} DESC" }

      select(Arel.sql(select_list.join(',')))
        .where(Arel.sql(conditions.join(' OR ')))
        .order(Arel.sql(ordering.join(',')))
        .distinct
    }
  end
end
