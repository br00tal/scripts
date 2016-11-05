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
po_u_token = full_config['pushover_user_token']
po_a_token = full_config['pushover_app_token']
subdomains = full_config['subdomains']
ttl = full_config['ttl']

if po_u_token.nil?
  use_pushover = false
else
  require 'pushover'
  use_pushover = true
end

# This function writes timestamped output
def logline(message)
  t = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  puts '[' + t + '] ' + message
end

def pushover(u_token, a_token, record, dns_ip, current_ip)
  Pushover.configure do |c|
    c.user = u_token
    c.token = a_token
  end
  message = "IP for #{record} is set to #{dns_ip} in DNS,"\
            " updating it to the current IP of #{current_ip}"
  Pushover.notification(message: message, title: 'IP changed!')
end

logline("START #{__FILE__}")

# Get the public IP address
public_ip = Net::HTTP.get URI ip_provider

# Connect to the GoDaddy API
api = Godaddy::Api.new api_key, api_secret

# Gather all the A records
a_records = api.get("/v1/domains/#{domain}/records/A")

# Check the A records against our managed list, and update if necessary
a_records.each do |a|
  if subdomains.include? a['name']
    if a['data'] != public_ip
      logline " #{a['name']} is #{a['data']}, not #{public_ip}, updating it..."
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
      if use_pushover
        pushover(po_u_token, po_a_token, a['name'], a['data'], public_ip)
      end
    elsif a['data'] == public_ip
      logline " #{a['name']}'s IPs match, doing nothing..."
    else
      exit 1
    end
  else
    logline " #{a['name']} is not managed, skipping..."
  end
end

logline("END #{__FILE__}")
