module ShareSupport
  extend ActiveSupport::Concern

  included do
    has_one  :shareable, as: :resource

    scope :publicly_shared, ->(table = table_name) {
      # Exclude records which do not have a shared record
      joins <<-SQL
        INNER JOIN shareables ON
          shareables.resource_id = #{table}.id AND
          shareables.resource_type = '#{table.to_s.classify}' AND
          (
            shareables.expires_at IS NULL OR
            shareables.expires_at > now()
          )
      SQL
    }

    scope :publicly_listed, -> {
      publicly_shared.where(shareables: { allow_listing: true })
    }
  end

  class_methods do
    def public_context(&block)
      if block_given?
        @@public_context = block
        return
      end

      base_class      = self
      custom_context  = defined?(@@public_context) ? @@public_context : nil

      Class.new(base_class) do
        def self.name
          base_class.name
        end

        default_scope { publicly_shared }

        self.instance_eval &custom_context if custom_context.present?
      end
    end
  end
end
