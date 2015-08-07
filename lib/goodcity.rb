require 'goodcity/config'

module Goodcity
  def self.config
    @@config ||= Goodcity::Config.new
  end
end
