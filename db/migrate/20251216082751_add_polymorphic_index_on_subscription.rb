class AddPolymorphicIndexOnSubscription < ActiveRecord::Migration[6.1]
  # Required for PostgreSQL concurrent index creation
  disable_ddl_transaction!

  def change
    add_index :subscriptions, [:subscribable_type, :subscribable_id], algorithm: :concurrently
  end
end
