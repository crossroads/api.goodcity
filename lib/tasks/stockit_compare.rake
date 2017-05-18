require 'goodcity/compare'

namespace :stockit do

  namespace :compare do
    %w(activities boxes codes countries locations pallets contacts local_orders organisations items orders).each do |task_name|
      desc %(Are #{task_name} in sync)
      task task_name => :environment do
        diffs = Goodcity::Compare.new
        diffs.send("compare_#{task_name}")
        diffs.each_diff{ |diff| puts diff.in_words unless diff.identical? }
        puts diffs.summary
      end
    end
  end

  desc "Are all GoodCity and Stockit objects in sync?"
  task compare: :environment do
    diffs = Goodcity::Compare.new
    diffs.compare
    puts diffs.in_words
  end

end