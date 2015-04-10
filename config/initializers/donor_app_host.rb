host_names = YAML::load_file(File.join(Rails.root, 'config', 'donor_app_host.yml'))
DONOR_APP_HOST = host_names[Rails.env]["host"]
