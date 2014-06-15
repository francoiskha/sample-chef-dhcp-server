#!/bin/bash
sudo chef-solo -c /vagrant/solo.rb -j /vagrant/attributes/default.json | tee -a run-chef-solo.log
#sudo ifconfig -a | tee -a run-chef-solo.log