require 'goodcity/compare'

namespace :stockit do

  namespace :compare do
    %w(activities boxes codes countries locations pallets contacts local_orders organisations items orders).each do |task_name|
      desc %(Are #{task_name} in sync)
      task task_name => :environment do
        Goodcity::Compare.new.send("compare_#{task_name}").in_words
      end
    end
  end

  desc "Are all GoodCity and Stockit objects in sync?"
  task compare: :environment do
    Goodcity::Compare.new.compare.in_words
  end

end