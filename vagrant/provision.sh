#!/bin/bash

sudo apt-get update
sudo apt-get install -y build-essential sysvbanner unzip

sudo mkdir /app
sudo chown vagrant:vagrant /app
