#!/usr/bin/ruby
require 'rubygems'
require 'god'

God.init do |god|
  god.pid_file_directory = '/home/lasindias/updater/pids'
end

%w{0 1}.each do |updater|
  God.watch do |w|
    # watch with no pid_file attribute set
    w.name = "updater_#{updater}"
    w.interval = 30.seconds # default
    w.start = "ruby /home/lasindias/updater/updater.rb"
    w.grace = 10.seconds
    
    w.behavior(:clean_pid_file)

    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.interval = 5.seconds
        c.running = false
      end
    end
    
    w.restart_if do |restart|
      restart.condition(:memory_usage) do |c|
        c.above = 150.megabytes
        c.times = [3, 5] # 3 out of 5 intervals
      end
      
      restart.condition(:cpu_usage) do |c|
        c.above = 50.percent
        c.times = 5
      end
    end
  end
end
