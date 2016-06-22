#!/usr/bin/ruby

require 'mysql2'

client = Mysql2::Client.new(:host => "mysql_host", :port => "mysql_port", :username => "mysql_user", :password => "mysql_password", :database => "powerdns_database")

zone_file_path = "/path/to/zones/"

domains = []
ttl = ""
name = ""
domain = ""
domain_id = ""

    
Dir.foreach(zone_file_path) do |item|
  next if item == '.' or item == '..' or item == 'deleted'
  domains << item.chomp(".zone")
  File.open(zone_file_path+ item).each do |line|
    line = line.split(" ")
  content = ""
  type = ""
  priority = "0"
     
        if line[0] == "$ORIGIN"
            domain = line[1].chomp(".")
            results = client.query("SELECT name,id FROM powerdns.domains WHERE name='#{domain}';")
            headers = results.fields
            if results.count > 0   # Delete existing records 
                puts domain + " exists"
                results.each do |row|
                    puts "Deleting existing records for " + row["name"]
                    domain_id = row["id"]
                    client.query("DELETE FROM powerdns.records WHERE domain_id='#{domain_id}';")
                end
            else                    # Add new domain
                   puts "Adding " + domain
                   client.query("INSERT INTO powerdns.domains (name, type) VALUES ('#{domain}', 'MASTER');")
                   domain_id = client.last_id
                   client.query("INSERT INTO powerdns.zones (domain_id, owner) VALUES ('#{domain_id}', '1');")               
            end
            
        elsif line[0] == "$TTL"
            ttl = line[1]
            
        elsif line[2] == "SOA"
            type = "SOA"
            name = line[0].chomp(".")
            line[3] = line[3].chomp(".") if line[3]
            line[4] = line[4].chomp(".") if line[4]
            for x in 3 .. line.length
                content+= line[x].to_s + " "
            end
            client.query("INSERT INTO powerdns.records (domain_id, name, type, content, ttl, prio, change_date) VALUES ('#{domain_id}', '#{name}', '#{type}', '#{content}', '#{ttl}', '#{priority}', NOW());") 
            
         elsif line[3] == "SRV" or line[3] == "MX"
            name = line[0].chomp(".")
            type = line[3]
            priority = line[4]
            line[line.length-1] = line[line.length-1].chomp(".")
            for x in 5 .. line.length
                content+= line[x].to_s + " "
            end
            client.query("INSERT INTO powerdns.records (domain_id, name, type, content, ttl, prio, change_date) VALUES ('#{domain_id}', '#{name}', '#{type}', '#{content}', '#{ttl}', '#{priority}', NOW());") 
         
         else
            name = line[0].chomp(".")
            type = line[3]
            line[4] = line[4].chomp(".") if line[4]
            for x in 4 .. line.length
                content+= (line[x].to_s + " ").chomp(".")
            end 
            ttl = line[1]
            client.query("INSERT INTO powerdns.records (domain_id, name, type, content, ttl, prio, change_date) VALUES ('#{domain_id}', '#{name}', '#{type}', '#{content}', '#{ttl}', '#{priority}', NOW());") 
         end

  end

end

power_domains = client.query("SELECT name, id FROM powerdns.domains;")

power_domains.each do |row|
    puts row["name"]
    unless domains.include?(row["name"])
        puts row["name"] + " exists in the database but wasn't in the DO backup, removing from powerdns."
        client.query("DELETE FROM powerdns.records WHERE domain_id='#{row["id"]}';")
        client.query("DELETE FROM powerdns.zones WHERE domain_id='#{row["id"]}';")
        client.query("DELETE FROM powerdns.domains WHERE id='#{row["id"]}';")
    end
  
end

