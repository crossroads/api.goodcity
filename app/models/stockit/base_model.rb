class Stockit::BaseModel < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "stockit_#{Rails.env}".to_sym
end
