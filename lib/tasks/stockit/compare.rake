require 'goodcity/compare'
require 'goodcity/compare/items'
require 'goodcity/compare/orders'

namespace :stockit do
  namespace :compare do
    %w(activities boxes codes countries locations pallets contacts local_orders organisations).each do |task_name|
      desc %(Are #{task_name} in sync)
      task task_name => :environment do
        diffs = Goodcity::Compare.new
        diffs.send("compare_#{task_name}")
        filename = "#{Rails.root}/log/stockit_compare_#{task_name}.txt"
        File.open(filename, 'w') do |file|
          file.puts diffs.summary
          diffs.each_diff { |diff| file.puts(diff.in_words) unless diff.identical? }
        end
        puts diffs.summary
        puts "Detailed report saved at #{filename}"
      end
    end

    desc "Compare items"
    task items: :environment do
      Goodcity::Compare::Items.run
    end

    desc "Compare orders"
    task orders: :environment do
      Goodcity::Compare::Orders.run
    end

  end

  desc "Are all GoodCity and Stockit objects in sync?"
  task compare: :environment do
    diffs = Goodcity::Compare.new
    diffs.compare
    puts diffs.in_words
  end

end
