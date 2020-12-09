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
end
