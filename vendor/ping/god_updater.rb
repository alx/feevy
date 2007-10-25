#!/usr/bin/ruby
require 'rubygems'
require 'god'

ROOT = File.dirname(__FILE__)
nb_updaters = 30

God.pid_file_directory = "#{ROOT}/pids/"

[*0...nb_updaters].each do |updater|
  God.watch do |w|
    # watch with no pid_file attribute set
    w.name = "updater_#{updater}"
    w.interval = 30.seconds # default
    w.start = "ruby #{ROOT}/updater.rb"
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
        c.above = 50.megabytes
        c.times = [3, 5] # 3 out of 5 intervals
      end
      
      restart.condition(:cpu_usage) do |c|
        c.above = 50.percent
        c.times = 5
      end
    end
  end
end
