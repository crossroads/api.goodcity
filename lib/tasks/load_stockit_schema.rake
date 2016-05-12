namespace :stock do
  task :load_stockit_schema do
    stockit_test = Rails.application.
      config.database_configuration['stockit_test']
    ActiveRecord::Base.establish_connection(stockit_test)
    load('db/stockit_schema.rb')
  end
end

