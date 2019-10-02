#!/bin/bash
set -eux

# remove old kernel packages.
yum remove -y $(rpm -qa 'kernel*' | grep -v "$(uname -r)" | tr \\n ' ')

# remove uneeded firmware.
yum remove -y linux-firmware

# make sure we cannot directly login as root.
usermod --lock root

# let our user use root permissions without sudo asking for a password.
groupadd -r admin
usermod -a -G admin vagrant
echo '%admin ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/admin
chmod 440 /etc/sudoers.d/admin

# install the vagrant public key.
# NB vagrant will replace it on the first run.
install -d -m 700 /home/vagrant/.ssh
pushd /home/vagrant/.ssh
curl -s https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -o authorized_keys
chmod 600 authorized_keys
chown -R vagrant:vagrant .
popd

# install the Guest Additions.
if [ -n "$(grep VBOX /sys/firmware/acpi/tables/APIC)" ]; then
# install the VirtualBox Guest Additions.
# this will be installed at /opt/VBoxGuestAdditions-VERSION.
# REMOVE_INSTALLATION_DIR=0 is to fix a bug in VBoxLinuxAdditions.run.
# See http://stackoverflow.com/a/25943638.
yum install -y kernel-headers kernel-devel gcc bzip2
rpm -qa 'kernel*' | sort
mkdir -p /mnt
mount /dev/sr1 /mnt
while [ ! -f /mnt/VBoxLinuxAdditions.run ]; do sleep 1; done
REMOVE_INSTALLATION_DIR=0 /mnt/VBoxLinuxAdditions.run --target /tmp/VBoxGuestAdditions
rm -rf /tmp/VBoxGuestAdditions
umount /mnt
eject /dev/sr1
else
# install the qemu-kvm Guest Additions.
yum install -y qemu-guest-agent spice-vdagent
fi

# disable the DNS reverse lookup on the SSH server. this stops it from
# trying to resolve the client IP address into a DNS domain name, which
# is kinda slow and does not normally work when running inside VB.
echo UseDNS no >>/etc/ssh/sshd_config

# use the up/down arrows to navigate the bash history.
# NB to get these codes, press ctrl+v then the key combination you want.
cat >>/etc/inputrc <<"EOF"
"\e[A": history-search-backward
"\e[B": history-search-forward
set show-all-if-ambiguous on
set completion-ignore-case on
EOF

# reset the machine-id.
# NB systemd will re-generate it on the next boot.
# NB machine-id is indirectly used in DHCP as Option 61 (Client Identifier), which
#    the DHCP server uses to (re-)assign the same or new client IP address.
# see https://www.freedesktop.org/software/systemd/man/machine-id.html
# see https://www.freedesktop.org/software/systemd/man/systemd-machine-id-setup.html
echo '' >/etc/machine-id
rm -f /var/lib/dbus/machine-id

# clean packages.
yum clean all

# zero the free disk space -- for better compression of the box file.
# NB prefer discard/trim (safer; faster) over creating a big zero filled file
#    (somewhat unsafe as it has to fill the entire disk, which might trigger
#    a disk (near) full alarm; slower; slightly better compression).
if [ "$(lsblk -no DISC-GRAN $(findmnt -no SOURCE /) | awk '{print $1}')" != '0B' ]; then
    fstrim -v /
else
    dd if=/dev/zero of=/EMPTY bs=1M || true; rm -f /EMPTY
fi
