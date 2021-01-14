Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Raises error for missing translations
  config.action_view.raise_on_missing_translations = true

  # Places email in tmp/mails/
  config.action_mailer.delivery_method = :file

  # Enable bullet logging in development mode
  # Bullet logs a scope of n+1 query improvements
  config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true
    Bullet.raise = false
    Bullet.rails_logger = true
  end

  # Since we are now using ActionMailer, we can even test email on Dev envionment
  # Steps:
  # 1. Uncomment the below config
  # 2. Add the user_name and password
  # 3. Go to https://www.google.com/settings/security/lesssecureapps and turn off "Allow less secure apps"
  #
  # Its advisible to turn off 2 Face Auth if using Gmail
  # In case if any other SMPT services are need to be used,
  # replace only 'smtp.gmail.com' with any available SMTP
  #
  # config.action_mailer.delivery_method = :smtp
  # config.action_mailer.smtp_settings = {
  #   address:              'smtp.gmail.com',
  #   port:                 587,
  #   domain:               'example.com',
  #   user_name:            '<email>',
  #   password:             '<password>',
  #   authentication:       'plain',
  #   enable_starttls_auto: true
  # }
  # This config will save the mails in the temp folder
  # If you need to test the delivery to SMTP, comment the below lines
  # and make use of above config
  ActionMailer::Base.delivery_method = :file
  ActionMailer::Base.file_settings = { :location => Rails.root.join('tmp/mail') }
end
