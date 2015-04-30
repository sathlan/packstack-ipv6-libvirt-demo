#   # enable link local
#   sysctl_br = "/proc/sys/net/ipv6/conf/#{bridge}/disable_ipv6"
#   # enable other ipv6 (not blocked by firewall anymore!)
#   # https://bugzilla.redhat.com/show_bug.cgi?id=634736
#   sysctl    = "/proc/sys/net/bridge/bridge-nf-call-ip6tables"
#
#   [sysctl_br, sysctl].each do |sys|
#     if %x"cat #{sys} | grep 0".empty?
#       system("echo 0 | sudo tee #{sys}")
#     end
#   end
#

def add_network(node, net)
  node.vm.network(
    :private_network,
    auto_config: false,
    libvirt__forward_mode: 'veryisolated',
    libvirt__dhcp_enabled: false,
    libvirt__network_name: net
  )
end

def netsted_enabled?
  IO.read('/sys/module/kvm_intel/parameters/nested').chomp == 'Y'
end

Vagrant.configure('2') do |config|

  if nested_enabled?
    config.vm.provider 'libvirt' do |lv|
      lv.cpu_mode = 'host-model'
      lv.nested = true
    end
  end

  config.vm.provider 'libvirt' do |lv|
    lv.nic_model_type = 'virtio'
    lv.disk_bus = 'virtio'
    lv.volume_cache = 'unsafe'
  end

  config.vm.define 'controller', primary: true do |node|
    node.vm.box = 'sofer/centos-70-base'
    node.vm.hostname = 'controller.vagrantup.com'
    node.vm.synced_folder '.', '/vagrant', disabled: true
    node.vm.provision "shell", path: "provision.sh", args: 'controller'
    add_network(node, 'mgmt')
    add_network(node, 'tunnel')
    add_network(node, 'public')
    node.vm.provider 'libvirt' do |lv|
      lv.memory = 4096
      lv.cpus = 2
    end
  end

  config.vm.define 'compute01' do |node|
    node.vm.box = 'sofer/centos-70-base'
    node.vm.hostname = 'compute01.vagrantup.com'
    node.vm.synced_folder '.', '/vagrant', disabled: true
    node.vm.provision "shell", path: "provision.sh", args: 'compute'
    node.vm.provider 'libvirt' do |lv|
      lv.memory = 1024
    end
    add_network(node, 'mgmt')
    add_network(node, 'tunnel')
  end
end

def bridge
  mapped_file = File.join(%w[.vagrant machines mapped_networks])
  if File.exist?(mapped_file)
    Marshal.load(IO.read(mapped_file))
  else
    {}
  end

end

def adjust_sysctl(bridge)
  # https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt
  # easy way to have ipv6 working with firewalld and libvirt 1.1.3

  # enable other ipv6 (not blocked by firewall anymore!)
  # https://bugzilla.redhat.com/show_bug.cgi?id=634736
  sysctl_ip6tables = "/proc/sys/net/bridge/bridge-nf-call-ip6tables"
  sysctl_iptables  = "/proc/sys/net/bridge/bridge-nf-call-iptables"
  msg_header = ["WARNING: if network doesn't work try:"]
  msg = []
  bridge.values.each do |br_name|
    require 'rexml/document'
    doc = REXML::Document.new `virsh --connect qemu:///system net-dumpxml #{br_name}`
    br = doc.root.elements["bridge"].attributes["name"]
    sysctl_br = "/proc/sys/net/ipv6/conf/#{br}/disable_ipv6"
    msg << "echo 0 | sudo tee #{sysctl_br}" if
      `cat #{sysctl_br} | grep 0`.empty?
  end
  [sysctl_iptables, sysctl_ip6tables].each do |sys|
    msg << "echo 0 | sudo tee #{sys}" if `cat #{sys} | grep 0`.empty?
  end
  puts((msg_header + msg).join("\n")) unless msg.empty?
end

adjust_sysctl(bridge)
