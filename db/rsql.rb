#!/usr/bin/env ruby
#
# run 'db/rsql.rb' from the app's dir to launch a MySQL shell against the
# specified db in databse.yml with user, passwd..
# 

require 'yaml'
require 'optparse'

config = nil

path = "."
while (File.exists?(path) and (path.length < 255) and !config)
        if (File.exists?("#{path}/config/database.yml"))
                File.open("#{path}/config/database.yml") do |f|
                        config = YAML.load(f)
                end
        else
                path = "../#{path}"
        end
end

unless (config)
        puts "Could not find database.yml"
        exit(-1)
end

command = "mysql"
verbose = false

opts = OptionParser.new
opts.on("-v", "--verbose") { verbose = true }
opts.on("-d", "--dump") { command = "mysqldump" }

args = opts.parse(*ARGV)

environ = (args[0] or ENV['RAILS_ENV'] or 'development')

if (config and config[environ])
        config = config[environ]

        puts config.inspect if (verbose)

        exec(command,
                "--user=#{config['username']}",
                "--password=#{config['password']}",
                "--host=#{config['host']}",
                "--port=#{config['port'] or 3306}",
                config['database']
        )
elsif (config)
        print "Could not find environment #{environ} in configuration file\n"
        exit(-2)
else
        print "Could not find or read Rails configuration file\n"
        exit(-1)
end