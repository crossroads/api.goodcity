server 'goodcity-staging.eastasia.cloudapp.azure.com:59207', user: 'deployer', roles: %w{web app db}
set :branch, ENV['BRANCH'] || 'master'