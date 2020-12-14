module ShareSupport
  extend ActiveSupport::Concern

  included do
    scope :publicly_shared, -> {
      # Exclude records which do not have a shared record
      joins <<-SQL
        INNER JOIN shareables ON 
          shareables.resource_id = #{table_name}.id AND
          shareables.resource_type = '#{self.name.demodulize}' AND
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

      Class.new(self) do 
        def self.name
          base_class.name
        end
        
        default_scope { publicly_shared }

        custom_context.call if custom_context.present?
      end
    end
  end
end
