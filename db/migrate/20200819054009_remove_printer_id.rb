class RemovePrinterId < ActiveRecord::Migration
  def up
    User.find_each do |user|
      if user.printer_id
        PrintersUser.create(user: user, printer_id: user.printer_id, tag: "stock")
      end
    end
    remove_column :users, :printer_id, :integer
  end

  def down
    add_column :users, :printer_id, :integer
  end
end