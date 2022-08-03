# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Configuring hardware resources.
  config.vm.provider "virtualbox" do |v|
    v.memory = 6144
    v.cpus = 4
    v.gui = false
  end
  # Customizing Ubuntu server.
  config.vm.define "grafana" do |g|
    g.vm.box = "bento/ubuntu-20.04"
    g.vm.box_check_update = false
    g.vm.hostname = "grafana"
    # Defining the network.
    g.vm.network "private_network", ip: "192.168.56.55"
    g.vm.network "forwarded_port", guest: 80, host: 9001
    # Preparing Docker installation.
    g.vm.provision "shell", inline: <<-SHELL
      tee /etc/hosts << STOP
127.0.0.1    	localhost
127.0.1.1    	grafana
STOP
    SHELL
    # Script to bootstrap.
    g.vm.provision "shell", path: "Docker.sh", privileged: true
  end
  # Customizing Ubuntu server.
    config.vm.define "dokuwiki" do |d|
        d.vm.box = "bento/ubuntu-20.04"
        d.vm.box_check_update = false
        d.vm.hostname = "dokuwiki"
        # Defining the network.
        d.vm.network "private_network", ip: "192.168.56.60"
        d.vm.network "forwarded_port", guest: 80, host: 8080
        d.vm.network "forwarded_port", guest: 80, host: 9001
        # Preparing Dokuwiki installation.
        d.vm.provision "shell", inline: <<-SHELL
         tee /etc/hosts << STOP
127.0.0.1    	localhost
127.0.1.1    	dokuwiki
STOP
        SHELL
        # Script to bootstrap.
        d.vm.provision "shell", path: "Dokuwiki.sh", privileged: true
      end
      # Customizing Ubuntu server.
      config.vm.box = "bento/ubuntu-20.04"
      config.vm.box_check_update = false
      config.ssh.forward_agent = true
      config.vm.define "osticket" do |o|
        o.vm.hostname = "osticket"
        # Defining the network.
        o.vm.network "private_network", ip: "192.168.56.90"
        o.vm.network "forwarded_port", guest: 80, host: 8081
        # Preparing osTicket installation.
        o.vm.provision "shell", inline: <<-SHELL
          tee /etc/hosts << STOP
127.0.0.1    	localhost
127.0.1.1    	osticket
STOP
        SHELL
        # Script to bootstrap.
      o.vm.provision "shell", path: "osTicket.sh", privileged: true
      end
  # Customizing Ubuntu server.
    config.vm.define "portainer" do |p|
      p.vm.box = "bento/ubuntu-20.04"
      p.vm.box_check_update = false
      p.vm.hostname = "portainer"
      # Defining the network.
      p.vm.network "private_network", ip: "192.168.56.70"
      p.vm.network "forwarded_port", guest: 80, host: 9000
      # Preparing Portainer installation.
      p.vm.provision "shell", inline: <<-SHELL
        tee /etc/hosts << STOP
127.0.0.1    	localhost
127.0.1.1    	portainer
STOP
      SHELL
      # Script to bootstrap.
      p.vm.provision "shell", path: "Portainer.sh", privileged: true
    end
end
