class AddPrintersUsers
  def self.apply!
    new.apply
  end

  def apply
    User.where('printer_id IS NOT NULL').find_each do |user|
      PrintersUser.create(user: user, printer_id: user.printer_id, tag: "stock")
    end
    ActiveRecord::Base.connection.execute("Alter table USERS DROP printer_id;")
  end
end