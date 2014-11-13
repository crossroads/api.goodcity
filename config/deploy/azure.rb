# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server definition into the
# server list. The second argument is a, or duck-types, Hash and is
# used to set extended properties on the server.

server 'goodcity.cloudapp.net', user: 'deployer', roles: %w{web app}
#set :ssh_options, { :forward_agent => true }
