class Message < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :recipient, polymorphic: true
  belongs_to :sender, class_name: 'User', inverse_of: :messages

end
