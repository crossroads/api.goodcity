require 'goodcity/designed_data'

#
# The designed dataset: real reference data, synthetic people, a declared spine of
# stock and order cases, and profile-sampled filler. See db/demo/designed/README.md.
#
#   rake db:demo:designed            # build into an empty database (reference data loaded)
#   rake db:demo:designed SEED=7     # a different (still deterministic) dataset
#   rake db:demo:designed:check      # spine assertions + conformance to profile.json
#
namespace :db do
  namespace :demo do
    desc 'Build the designed demo dataset (reference data must already be loaded)'
    task designed: :environment do
      abort('The designed dataset is never built in production. Aborting!') if Rails.env.production?
      if Package.exists? || Order.exists? || User.where.not(mobile: SYSTEM_USER_MOBILE).exists?
        abort('This database already holds stock, orders or users. The designed dataset is built into a fresh ' \
              'database with only reference data loaded (goodcity-local: scripts/build-designed.sh).')
      end

      seed = (ENV['SEED'].presence || Goodcity::DesignedData::DEFAULT_SEED).to_i
      Goodcity::DesignedData.new(seed: seed).generate!
    end

    namespace :designed do
      desc 'Assert the designed spine cases exist and the dataset conforms to profile.json'
      task check: :environment do
        ok = Goodcity::DesignedData::Checks.new.run
        exit(1) unless ok
      end
    end
  end
end
