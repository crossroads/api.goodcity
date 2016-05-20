server 'api.goodcity.hk:62422', user: 'deployer', roles: %w{web app db}, primary: true
server 'goodcity-production.cloudapp.net:62423', user: 'deployer', roles: %w{web app}
set :branch, :live
