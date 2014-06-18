#!/bin/bash
wget -O dhcp.zip https://github.com/spheromak/dhcp-cook/archive/0aaced436c4399a9c2f4af9c5df72659663b2c7a.zip 
unzip dhcp.zip && mv dhcp-cook-0aaced436c4399a9c2f4af9c5df72659663b2c7a dhcp
rm dhcp.zip
wget -O helpers-databags.zip https://github.com/spheromak/helpers-databags-cookbook/archive/a70297ffafcfdf04bc9ee3d611979f5cddaa5d7d.zip
unzip helpers-databags.zip && mv helpers-databags-cookbook-a70297ffafcfdf04bc9ee3d611979f5cddaa5d7d helpers-databags
rm helpers-databags.zip
wget -O ruby-helper.zip https://github.com/spheromak/ruby-helper-cookbook/archive/d4b20c6c68826f5f6d42a603c1e926fceca0cdf1.zip 
unzip ruby-helper.zip && mv ruby-helper-cookbook-d4b20c6c68826f5f6d42a603c1e926fceca0cdf1 ruby-helper
rm ruby-helper.zip