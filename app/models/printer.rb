class Printer < ApplicationRecord
  has_many   :printers_users
  has_many   :users, through: :printers_users
  belongs_to :location

  scope :active, -> { where(active: true) }

  before_destroy :reset_user_printers

  private

  def reset_user_printers
    fallback_printer_id = Printer.where.not(id: id).first&.id || nil
    User.where(printer_id: id).update_all(printer_id: fallback_printer_id)
  end
end
