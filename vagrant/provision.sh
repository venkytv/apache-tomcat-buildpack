#!/bin/bash

sudo apt-get update
#sudo apt-get install -y build-essential ruby libopenssl-ruby unzip
sudo apt-get install -y build-essential unzip

sudo mkdir /app
sudo chown vagrant:vagrant /app
