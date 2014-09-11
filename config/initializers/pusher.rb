require 'pusher'
Pusher.logger = Rails.logger
Pusher.encrypted = ENV['PUSHER_ENCRYPTED'] == 'true'
