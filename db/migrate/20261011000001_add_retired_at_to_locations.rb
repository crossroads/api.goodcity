# A retired location stays on every record that points at it (stock history, stocktakes, printers, goods types), but
# the new stock app stops offering it for new stock (GET /locations?exclude_retired=true). Additive and nullable: the
# legacy apps never read it, and every existing response keeps its shape.
class AddRetiredAtToLocations < ActiveRecord::Migration[6.1]
  def change
    add_column :locations, :retired_at, :datetime
  end
end
