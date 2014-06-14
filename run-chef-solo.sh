#!/bin/bash
sudo chef-solo -c solo.rb -j master.json | tee -a run-chef-solo.log
sudo ifconfig -a | tee -a run-chef-solo.log