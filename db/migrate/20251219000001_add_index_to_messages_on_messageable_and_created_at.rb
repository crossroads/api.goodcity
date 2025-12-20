class AddIndexToMessagesOnMessageableAndCreatedAt < ActiveRecord::Migration[6.1]
  # Creating the index concurrently avoids long table locks on large tables.
  # Postgres-only: `order:` and `algorithm: :concurrently` are Postgres features.
  disable_ddl_transaction!

  def change
    unless index_exists?(:messages, name: 'index_messages_on_messageable_and_created_at')
      add_index :messages,
                [:messageable_type, :messageable_id, :created_at],
                name: 'index_messages_on_messageable_and_created_at',
                order: { created_at: :desc },
                algorithm: :concurrently
    end
  end
end
