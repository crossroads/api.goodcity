class StockitDesignation < ActiveRecord::Base
  belongs_to :detail, polymorphic: true
  belongs_to :stockit_contact
  belongs_to :stockit_organisation
end
