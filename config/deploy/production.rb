ip = ENV["CI"] ? "api.goodcity.hk:62422" : "10.25.0.5:22"
server ip, user: 'deployer', roles: %w{web app db}, primary: true
# server 'goodcity-production.cloudapp.net:62423', user: 'deployer', roles: %w{web app}
set :branch, :live
