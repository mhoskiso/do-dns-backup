## Digitalocean DNS backup

At the minimum, you can use these scripts to create local copies of your domain records managed at Digitalocean. Each time you run retrieve_dns.rb, individual zone files will be created for each domain. If you delete a domain in the Digitalocean management panel, the backup zone file will be moved to a "deleted" folder the next time you run the script. If you want to take it a step further, you can use convert_to_powerdns.rb to keep another nameserver updated in case Digitalocean nameservers become unavailable. Follow this guide to setup a dns server that works with the script:
https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-powerdns-with-a-mariadb-backend-on-ubuntu-14-04
Add this server as an additional nameserver at your domain registrar.

## Requirements
* ruby 2.2.1p85 (This is the version I have installed, different versions probably work)
* Install the following gems: droplet_kit fileutils mail mysql2 dnsruby

## retrieve_dns.rb
Retrieves domain records from Digitalocean and saves the zone files. Overwrites existing zone file each time run and will move zone files for domains that are no longer in Digitalocean DNS to a deleted folder.

## convert_to_powerdns.rb
Parses the backup zone files and copies the records to a Powerdns MySQL database. Only tested with the DNS records Digitalocean supports.

## add_nameserver.rb
If you create a new nameserver from your Digitalocean dns backups, you can use this to add the new nameserver to all of your domains at Digitalocean. Reads the backup zone files to determine which domains don't currently have the new nameserver record.

## old-domains.rb
Checks for domains that are no longer using DO nameservers or might be expired. I used to have this automatically delete them from Digitalocean, but a few false positives on non-existant domains occured.

## Automation
Setup a similar cron job pointing to ruby and the script:

0 0 * * * /usr/local/bin/ruby /path/to/dns/retrieve_dns.rb

15 0 * * * /usr/local/bin/ruby /path/to/dns/convert_to_powerdns.rb

30 0 * * * /usr/local/bin/ruby /path/to/dns/add_nameserver.rb

45 0 * * * /usr/local/bin/ruby /path/to/dns/old-domains.rb
