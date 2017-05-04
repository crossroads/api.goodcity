require 'goodcity/compare'

namespace :stockit do

  namespace :compare do

    desc "Are GoodCity and Stockit activities in sync?"
    task activities: :environment do
      Goodcity::Compare.compare
    end

  end

  task :compare => ["compare:activities"]

end