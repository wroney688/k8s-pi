# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">= 1.8.6"

required_plugins = %w(vagrant-triggers)
required_plugins.push('vagrant-winnfsd')
required_plugins.push('vagrant-cachier')

VAGRANT_CACHE_DOCKER=true
required_plugins.each do |plugin|
  need_restart = false
  puts "Looking for #{plugin}"
  unless Vagrant.has_plugin? plugin
    puts "Installing #{plugin}"
    system "vagrant plugin install #{plugin}"
    need_restart = true
  end
  exec "vagrant #{ARGV.join(' ')}" if need_restart
end

node_cnt = 1
node_cpu = 4
node_mem = 4
puts "Node Count = #{node_cnt}"
puts "Node CPU cores = #{node_cpu}"
puts "Node Memory = #{node_mem} GB"

#using TEST-NET from RFC3330 for NFS
base_ip = "192.0.2"

master_ip = "192.168.10.20"


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "CentOS7"
  config.vm.box_url = "http://cloud.centos.org/centos/7/vagrant/x86_64/images/CentOS-7-x86_64-Vagrant-1711_01.VirtualBox.box"
  config.cache.scope = :box
  
  config.vm.provision "shell", privileged: true, inline: "/bin/sh /vagrant/scripts/install-common.sh #{master_ip}"
  config.vm.synced_folder ".", "/vagrant", type: "nfs"

  (1..node_cnt).each do |i|
    ndx = i.dup
    config.vm.define "x86-node-#{ndx}" do |node|
      node.vm.hostname = "x86-node-#{ndx}"
      node.vm.provider :virtualbox do |v|
        v.check_guest_additions = false
        v.functional_vboxsf = false
        v.cpus = node_cpu
        v.memory = node_mem * 1024
        v.name = node.vm.hostname
      end        
      node.vm.network :private_network, ip: "#{base_ip}.#{101+ndx}"
      node.vm.network :public_network
      node.vm.provision "shell", privileged: true, inline: "/bin/sh /vagrant/scripts/install-node.sh #{master_ip}"

    end
  end
end

