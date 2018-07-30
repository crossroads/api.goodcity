require 'capistrano/setup'
require 'capistrano/deploy'
require 'capistrano/rvm'
require 'capistrano/bundler'
require 'capistrano/rails/migrations'
require 'capistrano/sidekiq'
require 'capistrano/rake'
require 'rollbar/capistrano3'
require "whenever/capistrano"
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
