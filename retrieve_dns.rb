#!/usr/bin/ruby

require 'droplet_kit'
require 'fileutils'
require 'mail'

do_access_token = "stick your api token here"
zone_file_path = "/path/to/zones/"
deleted_file_path = zone_file_path + "deleted/"
backup_count = 0

client = DropletKit::Client.new(access_token: "#{do_access_token}")
message_body = ""

domains = client.domains.all

FileUtils::mkdir_p (zone_file_path) unless File.directory?(zone_file_path)
FileUtils::mkdir_p (deleted_file_path) unless File.directory?(deleted_file_path)

# Write zone files for domains at Digital Ocean
puts "Creating zone file backups from Digital Ocean"
domains.each do |domain|
backup_count += 1
    File.open(zone_file_path + domain.name + '.zone', "w"){|file| file.puts domain.zone_file}
end

# Cleanup zone files from previous backups that are no longer at Digital Ocean
puts "Checking for zone files that are no longer at Digital Ocean and removing from backup"
Dir.foreach(zone_file_path) do |item|
  next if item == '.' or item == '..' or item == 'deleted'
  
  unless domains.find {|i| i["name"] == "#{item.chomp(".zone")}"}
    # puts "#{item.chomp(".zone")} Not found at DO, moving to deleted folder "
    message_body = message_body +  "#{item.chomp(".zone")} Not found at DO, moving to deleted folder " + "\n"
    FileUtils.mv(zone_file_path + item, deleted_file_path + item)
  end
  
  
end

unless message_body == ""
     message_body = "#{backup_count} Domains Backed up" + "\n" + message_body
     mail = Mail.new do
         from     'admin@domain.com'
         to       'admin@domain.com'
         subject  'DNS Backup Report'
         body     message_body
     end
     mail.delivery_method :sendmail
     mail.deliver
 end