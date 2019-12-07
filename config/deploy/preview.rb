server 'api-staging.goodcity.hk:59207', user: 'deployer', roles: %w{web app db}
set :branch, :preview
set :deploy_to, '/opt/rails/goodcity_server_preview'
