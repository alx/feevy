require 'rubygems'
require 'daemons'

options = {
  :app_name   => "feevy_updater",
  :ARGV       => ['start', '-f'],
  :dir_mode   => :script,
  :dir        => 'pids',
  :multiple   => true,
  :backtrace  => true,
  :monitor    => true,
  :log_output => true
}
	
Daemons.run(File.join(File.dirname(__FILE__), 'updater.rb'), options)
