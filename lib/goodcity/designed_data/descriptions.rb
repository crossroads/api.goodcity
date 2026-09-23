module Goodcity
  class DesignedData
    #
    # Descriptions for filler stock, in the POST-cleanup house style: sentence case,
    # specific, key attributes present, consistent wording across similar items. See
    # db/demo/designed/descriptions.yml ("{a|b|c}" picks one alternative).
    #
    class Descriptions
      def initialize(ctx)
        @ctx = ctx
        @bank = DesignedData.load_yaml('descriptions')
      end

      def for(code, type_name)
        templates = @bank.fetch('codes', {})[code]
        return @ctx.expand(@ctx.pick(templates)) if templates.present?

        # Codes with no curated wording: the type's own name, lightly qualified.
        base = type_name.to_s.sub(/\APALLET OF /i, 'Pallet of ').sub(/\A(.)/) { Regexp.last_match(1).upcase }
        qualifier = @ctx.pick(@bank.fetch('generic_qualifiers'))
        qualifier.present? ? "#{base}, #{qualifier}" : base
      end

      def chat
        @bank.fetch('chat')
      end

      def sets
        @bank.fetch('sets')
      end
    end
  end
end
