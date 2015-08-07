#
# USAGE:
# Goodcity::Config.new.jwt
# Goodcity::Config.jwt

require 'hashie'

module Goodcity
  class Config < Hashie::Mash

    include Hashie::Extensions::MethodAccess

    def initialize(source_hash = nil, default = nil, &blk)
      source_hash ||= Rails.application.secrets.to_h
      super(source_hash, default, &blk)
    end

  end
end
