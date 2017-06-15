require 'goodcity/compare_v2'

namespace :stockit do

  namespace :compare do
    Goodcity::CompareV2::OBJECT_NAMES.each do |task_name|
      desc %(Are #{task_name} in sync)
      task task_name => :environment do
        comparision = Goodcity::CompareV2.new(task_name)
        comparision.compare
        filename = "#{Rails.root}/log/stockit_compare_#{task_name}.txt"
        File.open(filename, 'w') do |file|
          file.puts comparision.summary
          file.puts comparision.in_words
        end
        puts comparision.summary
        puts "Detailed report saved at #{filename}"
      end
    end
  end

end