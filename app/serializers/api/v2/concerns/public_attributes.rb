module Api::V2::Concerns
  module PublicAttributes
    extend ActiveSupport::Concern

    included do
      public_attribute :public_uid do |object|
        Shareable.public_uid_of(object)
      end
    end

    class_methods do
      def public_attribute(attribute, &block)
        show_public = Proc.new { |_, params = {}| params[:include_public_attributes] == true }

        if block_given?
          attribute(attribute, if: show_public, &block)
        else
          attribute(attribute, if: show_public)
        end
      end
    end
  end
end
