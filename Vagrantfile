# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "lucid64"
  config.vm.box_url = "http://files.vagrantup.com/lucid64.box"
  config.vm.provision "shell", path: "vagrant/provision.sh"
  config.vm.network :forwarded_port, host: 12345, guest: 12345
end
