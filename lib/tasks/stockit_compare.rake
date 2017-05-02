require 'goodcity/compare'

namespace :stockit do
  namespace :compare do

    desc "Compare everything"
    task default: :environment do
      activities
    end

    desc "Are GoodCity and Stockit activities in sync?"
    task activities: :environment do
      Goodcity::Compare.compare
    end

  end
end