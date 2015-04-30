install_repo()
{
    yum install -y http://rdoproject.org/repos/openstack-kilo/rdo-release-kilo.rpm
    sudo curl -o /etc/yum.repos.d/delorean.repo http://trunk.rdoproject.org/kilo/centos7/current/delorean-kilo.repo

#    curl -o /etc/yum.repos.d/delorean.repo  http://trunk.rdoproject.org/centos70/current/delorean.repo
#    yum install -y https://repos.fedorapeople.org/repos/openstack/openstack-kilo/rdo-release-kilo-0.noarch.rpm
    yum update -y
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
            ;;
    *)
            echo "Do not know $1"
            exit 1
esac
