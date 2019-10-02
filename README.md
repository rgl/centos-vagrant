This builds an up-to-date Vagrant CentOS Base Box.

Currently this targets [CentOS](https://www.centos.org/) 8.


# Usage

Install [Packer](https://www.packer.io/), [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/).

## qemu-kvm usage

Install qemu-kvm:

```bash
apt-get install -y qemu-kvm
apt-get install -y sysfsutils
systool -m kvm_intel -v
```

Type `make build-libvirt` and follow the instructions.

Try the example guest:

```bash
cd example
apt-get install -y virt-manager libvirt-dev
vagrant plugin install vagrant-libvirt
vagrant up --provider=libvirt
vagrant ssh
exit
vagrant destroy -f
```

## VirtualBox usage

Install [VirtuaBox](https://www.virtualbox.org/).

Type `make build-virtualbox` and follow the instructions.

Try the example guest:

```bash
cd example
vagrant up --provider=virtualbox
vagrant ssh
exit
vagrant destroy -f
```


# Kickstart

The CentOS installation iso uses the Anaconda installer to install CentOS.
During the installation it will ask you some questions and it will also
store your anwsers in the `/root/anaconda-ks.cfg` (aka kickstart) file.
This file is later used to fully automate a new installation by specifying
its location in the `inst.ks` kernel command line argument.


# Reference

* [Boot options](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/performing_an_advanced_rhel_installation/kickstart-and-advanced-boot-options_installing-rhel-as-an-experienced-user)
* [Kickstart manual](http://pykickstart.readthedocs.io/en/latest/kickstart-docs.html)
* [Kickstart installations](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/performing_an_advanced_rhel_installation/kickstart-installation-basics_installing-rhel-as-an-experienced-user)
* [Mirror list](https://www.centos.org/download/mirrors/)
* [Standard CentOS cloud image sources](https://github.com/CentOS/sig-cloud-instance-build)
