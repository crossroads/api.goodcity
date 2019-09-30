class Computer < ActiveRecord::Base
  belongs_to :country
  has_one :package, as: :detail, dependent: :destroy
  after_save :sync_to_stockit

  def self.create_detail(attributes)
    params = ActiveSupport::HashWithIndifferentAccess.new(attributes)
    begin
      create(params)
    rescue => exception
      puts exception
    end
  end

  def update_detail(attributes)
    params = ActiveSupport::HashWithIndifferentAccess.new(attributes)
    update(params)
  end

  private
  def sync_to_stockit
    # do sync related stuff here
  end
end
