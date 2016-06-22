#!/usr/bin/ruby

require 'droplet_kit'
require 'dnsruby'
include Dnsruby
require 'fileutils'
require 'mail'


nameservers = ['ns1.digitalocean.com','ns2.digitalocean.com','ns3.digitalocean.com']
do_access_token = "stick your api token here"
zone_file_path = "/path/to/zones/"
deleted_file_path = zone_file_path + "deleted/"
message_body = ""

FileUtils::mkdir_p (zone_file_path) unless File.directory?(zone_file_path)
FileUtils::mkdir_p (deleted_file_path) unless File.directory?(deleted_file_path)

resolver = Dnsruby::DNS.new({:nameserver=>["8.8.8.8"]})
 
client = DropletKit::Client.new(access_token: "#{do_access_token}")

Dir.foreach(zone_file_path) do |item|
  next if item == '.' or item == '..' or item == 'deleted'
  match = 0
  begin 
    resolver.each_resource(item.chomp(".zone"), 'NS') do |rr|
    unless nameservers.include?(rr.domainname.to_s)
        match = 1
        #puts  "#{rr.name} #{rr.domainname}"
    end
  end  
    if match != 0
        message_body = message_body +  "#{item.chomp(".zone")} has a different nameserver. Please review and delete from DO." + "\n"
    end
       

  rescue Dnsruby::NXDomain
   # puts "#{item.chomp(".zone")} doesn't exist according to Google. Removing from DO and moving to deleted folder."
    message_body = message_body +  "#{item.chomp(".zone")} doesn't exist according to Google. Please review and delete from DO." + "\n"
    FileUtils.mv(zone_file_path + item, deleted_file_path + item)
   # client.domains.delete(name: item.chomp(".zone"))
  end  
   
end

unless message_body == ""
      mail = Mail.new do
          from     'admin@domain.com'
          to       'admin@domain.com'
            subject  'DNS Bad Domains Report'
            body     message_body
      end
        mail.delivery_method :sendmail
        mail.deliver
end


