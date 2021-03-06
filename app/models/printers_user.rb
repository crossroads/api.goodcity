class PrintersUser < ActiveRecord::Base
  belongs_to :printer
  belongs_to :user
  validates :printer_id, uniqueness: { scope: %i[user_id tag] }
end
