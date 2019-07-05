require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_view/railtie"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module GoodCityServer
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Hong Kong'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.autoload_paths += %W(#{config.root}/lib/classes)

    # config.active_record.schema_format = :sql

    config.i18n.available_locales = ['en', 'zh-tw']

    config.filter_parameters << :otp_secret_key

    config.active_job.queue_adapter = :sidekiq

    config.lograge.enabled = true
    config.lograge.enabled = Lograge::Formatters::Json.new
    config.log_formatter = proc do |severity, datetime, progname, msg|
      "time=\"#{datetime.iso8601(3)}\" level=\"#{severity}\" pid=\"#{Process.pid}\" #{msg.to_s.gsub('"', "'")}\n"
    end

    config.active_record.raise_in_transactional_callbacks = true
  end
end
