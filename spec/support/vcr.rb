require 'vcr'

VCR.configure do |c|
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = false
  c.hook_into :webmock
  c.cassette_library_dir     = 'spec/vcr/cassettes'
  c.debug_logger             = File.open('log/vcr_debug.log', 'w')
  c.default_cassette_options = { record: :new_episodes }
  c.filter_sensitive_data('<twilio account sid>') { ENV['TWILIO_ACCOUNT_SID'] }
  c.filter_sensitive_data('<twilio auth token>') { ENV['TWILIO_AUTH_TOKEN'] }
end
