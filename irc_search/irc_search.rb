#!/usr/bin/env ruby

# Required libraries/gems
require 'mimemagic'
require 'optparse'
require 'zlib'

# Define some variables
wc_logs = '~/.weechat/logs'
wc_logs_clean = Dir.glob(File.expand_path(wc_logs) + '/*')
matches = []

# Set up the options parser
helptext = nil
options = { 'nick' => nil, 'string' => nil }
parser = OptionParser.new do |opts|
  opts.banner = 'Usage: irc_search.rb [options] <search term>'
  opts.on('-n', '--nick nick', 'user\'s irc nick') do |nick|
    options['nick'] = nick
  end
  opts.on('-s', '--string \'search string\'',
          'search string (required)') do |string|
    options['string'] = string
  end
  opts.on('-h', '--help', 'displays help') do
    puts opts
    exit
  end
  helptext = opts
end
parser.parse!

# Validate required option(s)
if options['string'].nil?
  puts helptext
  exit 1
end

# Loop through the files and grab lines matching the search term
wc_logs_clean.each do |file|
  mtype = MimeMagic.by_magic(File.open(file))
  infile = open(file)
  if mtype == 'application/gzip'
    log_file = Zlib::GzipReader.new(infile)
  else
    log_file = infile
  end
  log_file.each_line do |line|
    l = line.downcase
    n = options['nick'].downcase
    s = options['string'].downcase
    if options['nick']
      nick_search = line.split(' ')
      ns = nick_search[2].to_s.downcase
      matches.push(line) if (ns =~ /#{n}/) && (l.include? s)
    else
      matches.push(line) if l.include? s
    end
  end
end

# Sort and print the matches array
puts matches.sort
