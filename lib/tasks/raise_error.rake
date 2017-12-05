namespace :rollbar do
  task :raise_error => :environment do
    raise "Test error from rake task"
  end
end