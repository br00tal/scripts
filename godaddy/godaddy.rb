#!/usr/bin/env ruby

# Require the required gems
require 'godaddy/api'
require 'json'
require 'net/http'

# Read the config file and set variables
working_dir = File.expand_path(File.dirname(__FILE__))
config_file = working_dir + '/godaddy_config.json'
config = File.read(config_file)
full_config = JSON.parse(config)
api_key = full_config['api_key']
api_secret = full_config['api_secret']
domain = full_config['domain']
ip_provider = full_config['ip_provider']
subdomains = full_config['subdomains']
ttl = full_config['ttl']

# Get the public IP address
public_ip = Net::HTTP.get URI ip_provider

# Connect to the GoDaddy API
api = Godaddy::Api.new api_key, api_secret

# Gather all the A records
a_records = api.get("/v1/domains/#{domain}/records/A")

# Check the A records against our managed list, and update if necessary
a_records.each do |a|
  puts a['data']
  if subdomains.include? a['name']
    puts "#{a['name']} is set to be managed, comparing IPs..."
    if a['data'] != public_ip
      puts "#{a['name']} is #{a['data']}, not #{public_ip}, updating it..."
      api.put(
        "/v1/domains/#{domain}/records/A/#{a['name']}",
        [
          {
            type: 'A',
            name: a['name'],
            data: public_ip,
            ttl: ttl
          }
        ]
      )
    elsif a['data'] == public_ip
      puts "#{a['name']}'s IPs match, doing nothing..."
    else
      puts 'Something strange happened, exiting...'
      exit 1
    end
  else
    puts "#{a['name']} is not managed, skipping..."
  end
end
