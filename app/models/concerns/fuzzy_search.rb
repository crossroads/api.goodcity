module FuzzySearch
  extend ActiveSupport::Concern

  class_methods do
    attr_reader :search_joins

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
    def search(search_text)
      sanitized_text = sanitize(search_text)
      similarities = self.search_props.map { |f| "SIMILARITY(#{f}, #{sanitized_text})" }

      fields = similarities + ["#{table_name}.*"]
      conditions = similarities.map { |s| "#{s} > #{similarity_threshold}" }
      ordering = similarities.map { |q| "#{q} DESC" }

      select(fields.join(','))
        .where(conditions.join(' OR '))
        .order(ordering.join(','))
        .distinct
    end


    #
    # Configuration of fuzzy search
    #
    # @param [string[]] props array of columns to search against
    # @param [float] tolerance the tolerance of the search between 0 and 1 \
    #     1 requires a perfect match and 0 lets any similarity through
    #
    # @return [<Type>] <description>
    #
    def configure_search(props: [], tolerance: 0.1)
      @search_props ||= []
      @search_props = (@search_props << props).flatten
      @similarity_threshold = tolerance
    end

    def similarity_threshold
      @similarity_threshold.present? ? @similarity_threshold : 0.1
    end

    def search_props
      return @search_props unless @search_props.blank?
      self.columns.select{ |c| c.type == :string }.map(&:name)
    end
  end
end

