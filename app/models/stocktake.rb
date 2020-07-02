class Stocktake < ActiveRecord::Base
  include StocktakeProcessor

  has_many    :stocktake_revisions
  belongs_to  :location
  belongs_to  :created_by, class_name: "User"

  alias_attribute :revisions, :stocktake_revisions

  state_machine :state, initial: :open do
    state :open, :closed, :cancelled

    event :reopen do
      transition [:closed, :cancelled] => :open
    end

    event :close do
      transition open: :closed
    end

    event :cancel do
      transition all - [:closed] => :cancelled
    end
  end
end
