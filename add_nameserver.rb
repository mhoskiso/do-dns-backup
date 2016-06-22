#!/usr/bin/ruby

require 'droplet_kit'


new_nameserver = "ns.domain.com"
do_access_token = "stick your api token here"
zone_file_path = "/path/to/zones/"
 
client = DropletKit::Client.new(access_token: "#{do_access_token}")

Dir.foreach(zone_file_path) do |item|
  next if item == '.' or item == '..' or item == 'deleted'
  unless File.open(zone_file_path + item).grep(/IN NS #{new_nameserver}./).length > 0
    puts "Adding " + new_nameserver + " to " + item.chomp(".zone")
    record = DropletKit::DomainRecord.new(type: 'NS', data: '#{new_nameserver}.')
    client.domain_records.create(record, for_domain: "#{item.chomp(".zone")}") 
  end
end

