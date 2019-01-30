require 'capistrano/setup'
require 'capistrano/deploy'
require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git
require 'capistrano/rvm'
require 'capistrano/bundler'
require 'capistrano/rails/migrations'
require 'capistrano/rake'
require 'rollbar/capistrano3'
require "whenever/capistrano"
require 'new_relic/recipes'
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
