class Company < ActiveRecord::Base
  has_many :offers

  def self.search(options)
    where('name ILIKE :search_text', search_text: "%#{options[:search_text]}%")
  end
end
