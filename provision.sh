#!/bin/bash
set -eux

# remove old kernel packages.
dnf remove -y $(rpm -qa 'kernel*' | grep -v "$(uname -r)" | tr \\n ' ')

# remove uneeded firmware.
dnf remove -y '*-firmware'

# make sure we cannot directly login as root.
usermod --lock root

# let all wheel users use root permissions without sudo asking for a password.
echo '%wheel ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

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
dnf install -y kernel-headers kernel-devel gcc bzip2
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
dnf install -y qemu-guest-agent spice-vdagent
fi

# install the nfs client to support nfs synced folders in vagrant.
dnf install -y nfs-utils

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

# reset the random-seed.
# NB systemd-random-seed re-generates it on every boot and shutdown.
# NB you can prove that random-seed file does not exist on the image with:
#       sudo virt-filesystems -a ~/.vagrant.d/boxes/centos-8-amd64/0/libvirt/box.img
#       sudo guestmount -a ~/.vagrant.d/boxes/centos-8-amd64/0/libvirt/box.img -m /dev/sda1 --pid-file guestmount.pid --ro /mnt
#       sudo ls -laF /mnt/var/lib/systemd
#       sudo guestunmount /mnt
#       sudo bash -c 'while kill -0 $(cat guestmount.pid) 2>/dev/null; do sleep .1; done; rm guestmount.pid' # wait for guestmount to finish.
# see https://www.freedesktop.org/software/systemd/man/systemd-random-seed.service.html
# see http://man7.org/linux/man-pages/man4/random.4.html
# see http://man7.org/linux/man-pages/man7/random.7.html
# see https://github.com/systemd/systemd/blob/master/src/random-seed/random-seed.c
# see https://github.com/torvalds/linux/blob/master/drivers/char/random.c
systemctl stop systemd-random-seed
rm -f /var/lib/systemd/random-seed

# clean packages.
dnf clean all

# zero the free disk space -- for better compression of the box file.
# NB prefer discard/trim (safer; faster) over creating a big zero filled file
#    (somewhat unsafe as it has to fill the entire disk, which might trigger
#    a disk (near) full alarm; slower; slightly better compression).
if [ "$(lsblk -no DISC-GRAN $(findmnt -no SOURCE /) | awk '{print $1}')" != '0B' ]; then
    fstrim -v /
else
    dd if=/dev/zero of=/EMPTY bs=1M || true; rm -f /EMPTY
fi
