class Offer < ActiveRecord::Base

  belongs_to :created_by, class_name: 'User', inverse_of: :offers
  has_many :messages, as: :recipient
  has_many :items, inverse_of: :offer

  scope :with_eager_load, -> {
    includes( [:created_by, {messages: :sender},
               {items: [:rejection_reason, :images, {messages: :sender}, { packages: :package_type }]}
           ])
  }

end
