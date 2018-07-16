require 'sidekiq-scheduler'
require 'rake'

class ImportSWDOrganisationsJob
  include Sidekiq::Worker

  def perform
    %x(bundle exec rake goodcity:import_swd_organisations)
  end
end
