namespace :db do
  desc "Add reporter pg user to all tables and views"
  task reporter: :environment do
    database_name = Rails.configuration.database_configuration[Rails.env]["database"]
    ActiveRecord::Base.connection.execute "GRANT CONNECT ON DATABASE #{database_name} TO reporter;"
    ActiveRecord::Base.connection.execute "GRANT USAGE ON SCHEMA public to reporter;"
    ActiveRecord::Base.connection.execute "GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO reporter;"
    ActiveRecord::Base.connection.execute "GRANT SELECT ON ALL TABLES IN SCHEMA public TO reporter;"
    ActiveRecord::Base.connection.execute "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO reporter;"
    ActiveRecord::Base.connection.execute "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO reporter;"
  end
end