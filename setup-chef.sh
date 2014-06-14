#!/bin/bash
echo "creating chef user and group"
sudo useradd chef
echo "adding chef user to root group"
sudo usermod -a -G root chef