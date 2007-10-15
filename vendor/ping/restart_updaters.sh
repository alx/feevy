#!/bin/sh
sudo killall -9 ruby
rm -f /home/lasindias/updater/pids/*
sudo gem update rfeedfinder rfeedreader
sudo god -c /home/lasindias/updater/god_updater.rb
