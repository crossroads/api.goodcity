class Company < ActiveRecord::Base
  has_many :offers

  validates :name, uniqueness: true

  def self.search(options)
    where('name ILIKE :search_text', search_text: "%#{options[:search_text]}%")
  end
end
