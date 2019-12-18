module GoodcityDeprecation
  extend ActiveSupport::Concern
  class_methods do
    def goodcity_deprecator
      @deprecator ||= ActiveSupport::Deprecation.new('1.0', 'Goodcity')
    end

    def gc_deprecate(method_names)
      deprecate(method_names.merge(deprecator: goodcity_deprecator))
    end
  end
end
