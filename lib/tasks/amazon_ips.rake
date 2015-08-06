#
# Services such as CircleCI are located in the Amazon 'us-east-1' region.
# To enable continuous deployment, we need to open up various IP ranges in the firewall.

require 'nestful'

namespace :amazon do

  desc "List Amazon IPs in the given ENV['REGION'] and ENV['SERVICE'] \
(Defaults: region 'us-east-1', service 'AMAZON').You can optionally output \
firewalld commands to cut and paste into your server. Use ENV['FIREWALLD']=true "
  task ips: :environment do
    region = ENV["REGION"] || "us-east-1"
    service = ENV["SERVICE"] || "AMAZON"
    firewalld = ENV["FIREWALLD"] == "true"
    response = Nestful.get("https://ip-ranges.amazonaws.com/ip-ranges.json")
    if response.status == 200
      blocks = JSON.parse(response.body)["prefixes"]
      ips = blocks.select{|blk| blk["region"] == region and blk["service"] == service}.map{|b| b["ip_prefix"]}
      if firewalld
        puts ips.map{|ip| "firewall-cmd --permanent --zone=external --add-source=#{ip}"}.join("\n")
        puts "firewall-cmd --reload"
      else
        puts ips.join(" ")
      end
    else
      puts "Error retrieving IP data from Amazon. (Response code #{response.status})"
    end
  end

  desc "List available Amazon regions to query"
  task regions: :environment do
    response = Nestful.get("https://ip-ranges.amazonaws.com/ip-ranges.json")
    if response.status == 200
      blocks = JSON.parse(response.body)["prefixes"]
      puts blocks.map{|blk| blk["region"]}.uniq.compact.to_yaml
    else
      puts "Error retrieving IP data from Amazon. (Response code #{response.status})"
    end
  end

  desc "List Amazon services"
  task services: :environment do
    response = Nestful.get("https://ip-ranges.amazonaws.com/ip-ranges.json")
    if response.status == 200
      blocks = JSON.parse(response.body)["prefixes"]
      puts blocks.map{|blk| blk["service"]}.uniq.compact.to_yaml
    else
      puts "Error retrieving IP data from Amazon. (Response code #{response.status})"
    end
  end

end
