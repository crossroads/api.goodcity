# frozen_string_literal: true

# Logic for which users to subscribe to each new message
module MessageSubscription
  extend ActiveSupport::Concern

  # Who gets subscribed to a new message (i.e. who can see each message)
  def subscribe_users_to_message
    Messages::Operations.new(message: self).subscribe_users_to_message
  end
end
