#!/bin/bash
sudo dhclient -r eth1 && sudo dhclient eth1 && sudo ifconfig -a