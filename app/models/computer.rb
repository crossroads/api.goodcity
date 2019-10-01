class Computer < ActiveRecord::Base
  belongs_to :country
  has_one :package, as: :detail, dependent: :destroy
  after_save :sync_to_stockit

  private
  def sync_to_stockit
    # do sync related stuff here
  end
end
