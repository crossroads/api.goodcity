ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

# Ruby 3.4 removed `File.exists?` (use `File.exist?`).
# Some older gems still call the removed method during load.
class << File
  unless respond_to?(:exists?)
    def exists?(path)
      exist?(path)
    end
  end
end

require 'bundler/setup' # Set up gems listed in the Gemfile.
require "logger" # Fix concurrent-ruby removing logger dependency which Rails itself does not have
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
