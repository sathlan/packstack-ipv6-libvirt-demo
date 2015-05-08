install_repo()
{
    yum install -y http://rdoproject.org/repos/openstack-kilo/rdo-release-kilo.rpm
    sudo curl -o /etc/yum.repos.d/delorean.repo http://trunk.rdoproject.org/kilo/centos7/current/delorean-kilo.repo
    yum update -y
}

install_packstack()
{
    yum install -y openstack-packstack
}
configure_gre_packstack()
{
    local conf="gre_test.txt"
    configure_common_packstack generic.txt
    sudo -u vagrant cp generic.txt ${conf}
    # tunnel :
    sed -i -e 's/CONFIG_NEUTRON_ML2_TYPE_DRIVERS.*/CONFIG_NEUTRON_ML2_TYPE_DRIVERS=gre/' "${conf}"
    sed -i -e 's/CONFIG_NEUTRON_ML2_TENANT_NETWORK_TYPES.*/CONFIG_NEUTRON_ML2_TENANT_NETWORK_TYPES=gre/' "${conf}"
    # tunnel :
    sed -i -e 's/CONFIG_NEUTRON_ML2_TUNNEL_ID_RANGES.*/CONFIG_NEUTRON_ML2_TUNNEL_ID_RANGES=1000:2000/' "${conf}"

    # tunnel: *** This must be the interface of the tunnel with the IPv4 on it !!! ****
    sed -i -e 's/CONFIG_NEUTRON_OVS_TUNNEL_IF.*/CONFIG_NEUTRON_OVS_TUNNEL_IF=eth2/' "${conf}"
}

configure_vlan_packstack()
{
    local conf="vlan_test.txt"
    configure_common_packstack generic.txt
    sudo -u vagrant cp generic.txt ${conf}

    sed -i -e 's/CONFIG_NEUTRON_ML2_TYPE_DRIVERS.*/CONFIG_NEUTRON_ML2_TYPE_DRIVERS=vlan/' "${conf}"
    sed -i -e 's/CONFIG_NEUTRON_ML2_TENANT_NETWORK_TYPES.*/CONFIG_NEUTRON_ML2_TENANT_NETWORK_TYPES=vlan/' "${conf}"
    sed -i -e 's/CONFIG_NEUTRON_ML2_VLAN_RANGES.*/CONFIG_NEUTRON_ML2_VLAN_RANGES=physnet1,physnet2:100:200/' "${conf}"
    sed -i -e 's/CONFIG_NEUTRON_OVS_BRIDGE_IFACES=.*/CONFIG_NEUTRON_OVS_BRIDGE_IFACES=br-ex:eth3,br-eth2:eth2/' "${conf}"
    sed -i -e 's/CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS=.*/CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS=physnet1:br-ex,physnet2:br-eth2/' "${conf}"
}

configure_common_packstack()
{
    local conf="${1:-generic.txt}"
    [ -e "${conf}" ] || sudo -u vagrant packstack --gen-answer-file=${conf}
    # remove swift :
    sed -i -e 's/^CONFIG_SWIFT_INSTALL.*/CONFIG_SWIFT_INSTALL=n/' "${conf}"

    # remove nagios :
    sed -i -e 's/^CONFIG_NAGIOS_INSTALL.*/CONFIG_NAGIOS_INSTALL=n/' "${conf}"

    # adjust ip :
    sed -i -e 's/CONFIG_CONTROLLER_HOST.*/CONFIG_CONTROLLER_HOST=fdf8:f53b:82e4::179/' "${conf}"

    # again for compute:
    sed -i -e 's/CONFIG_COMPUTE_HOSTS.*/CONFIG_COMPUTE_HOSTS=fdf8:f53b:82e4::179,fdf8:f53b:82e4::180/' "${conf}"

    # network host:
    sed -i -e 's/CONFIG_NETWORK_HOSTS.*/CONFIG_NETWORK_HOSTS=fdf8:f53b:82e4::179/' "${conf}"

    # glance, cinder:
    sed -i -e 's/CONFIG_STORAGE_HOSTS.*/CONFIG_STORAGE_HOSTS=fdf8:f53b:82e4::179/' "${conf}"

    # message (rabbitmq):
    sed -i -e 's/CONFIG_AMQP_HOST.*/CONFIG_AMQP_HOST=fdf8:f53b:82e4::179/' "${conf}"
    sed -i -e 's/CONFIG_AMQP_HOSTS.*/CONFIG_AMQP_HOSTS=fdf8:f53b:82e4::179/' "${conf}"

    # database:
    sed -i -e 's/CONFIG_MARIADB_HOST.*/CONFIG_MARIADB_HOST=fdf8:f53b:82e4::179/' "${conf}"

    sed -i -e 's/CONFIG_MARIADB_HOSTS.*/CONFIG_MARIADB_HOSTS=fdf8:f53b:82e4::179/' "${conf}"

    # tunnel :

    # don't configure demo:
    sed -i -e 's/CONFIG_PROVISION_DEMO.*/CONFIG_PROVISION_DEMO=n/' "${conf}"

    # mongodb:
    sed -i -e 's/CONFIG_MONGODB_HOST.*/CONFIG_MONGODB_HOST=fdf8:f53b:82e4::179/' "${conf}"

    # redis:
    sed -i -e 's/CONFIG_REDIS_MASTER_HOST.*/CONFIG_REDIS_MASTER_HOST=fdf8:f53b:82e4::179/' "${conf}"


    sed -i -e 's/CONFIG_MARIADB_HOSTS.*/CONFIG_MARIADB_HOSTS=fdf8:f53b:82e4::179/' "${conf}"

    # don't configure demo:
    sed -i -e 's/CONFIG_PROVISION_DEMO.*/CONFIG_PROVISION_DEMO=n/' "${conf}"

    # mongodb:
    sed -i -e 's/CONFIG_MONGODB_HOST.*/CONFIG_MONGODB_HOST=fdf8:f53b:82e4::179/' "${conf}"

    # redis:
    sed -i -e 's/CONFIG_REDIS_MASTER_HOST.*/CONFIG_REDIS_MASTER_HOST=fdf8:f53b:82e4::179/' "${conf}"
}

first_thing_to_run()
{
    cat > /home/vagrant/runme.sh <<EOF
echo "root password is 'vagrant'"
ssh-keygen
ssh-copy-id root@fdf8:f53b:82e4::179
ssh-copy-id root@fdf8:f53b:82e4::180

EOF
    chmod a+rx /home/vagrant/runme.sh
}

thing_to_test()
{
    cp /root/keystonerc_admin /home/vagrant/
    chmod a+r /home/vagrant/keystonerc_admin
    cat > /home/vagrant/testme.sh<<'EOF'
. /home/vagrant/keystonerc_admin
neutron router-create ipv6-router
neutron net-create ipv6-int-net
neutron subnet-create --name ipv6-int-subnet --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac ipv6-int-net 2012::/64
neutron net-create --router:external ipv6-ext-net
neutron subnet-create --name ipv6-ext-subnet --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac ipv6-ext-net 2014::/64
neutron router-interface-add ipv6-router ipv6-int-subnet
neutron router-gateway-set ipv6-router ipv6-ext-net
glance image-create --name "Fedora 21" --disk-format qcow2 --container-format bare --is-public True --copy http://download.fedoraproject.org/pub/fedora/linux/releases/21/Cloud/Images/x86_64/Fedora-Cloud-Base-20141203-21.x86_64.qcow2
nova secgroup-add-rule default tcp 22 22 ::0/0
nova secgroup-add-rule default icmp -1 -1 ::/0
nova flavor-create m1.nano 42 64 0 1
nova flavor-create m1.micro 84 192 0 1
# wait for nova image-list
sleep 60
# Adjust to a valide path!!
nova keypair-add --pub_key /home/vagrant/.ssh/id_rsa.pub default
net_id=$(neutron net-list | awk '/ipv6-int-net/{print $2}')
nova boot --config-drive=true --image 'Fedora 21' --flavor 84 --nic net-id=$net_id --security-groups default --availability-zone=nova:compute01.vagrantup.com --key-name default test01
nova boot --config-drive=true --image 'Fedora 21' --flavor 84 --nic net-id=$net_id --security-groups default --availability-zone=nova:controller.vagrantup.com --key-name default test02

EOF
    chmod a+rx /home/vagrant/testme.sh
}

setup_for_vlan()
{
    case $1 in
        compute)
            local ipv6=fdf8:f53b:82e5::180/64
            ;;
        controller)
            local ipv6=fdf8:f53b:82e5::179/64
            ;;
        *)
            echo "Unknow type ${1}"
            exit 1
    esac
    sudo ip addr flush dev eth2
    sudo ip addr add dev eth2 ${ipv6}
}
case $1 in
    compute)
            ip addr add dev eth1 fdf8:f53b:82e4::180/64
            ip link set dev eth1 up
            ip addr add 10.0.0.1/24 brd + dev eth2
            ip link set dev eth2 up
            install_repo
            ;;
    controller)
            ip addr add dev eth1 fdf8:f53b:82e4::179/64
            ip link set dev eth1 up
            ip addr add 10.0.0.2/24 brd + dev eth2
            ip link set dev eth2 up
            ip link set dev eth3 up
            install_repo
            install_packstack
            configure_gre_packstack
            configure_vlan_packstack
            first_thing_to_run
            thing_to_test
            ;;
    *)
            echo "Do not know $1"
            exit 1
esac
