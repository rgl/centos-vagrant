VERSION=$(shell jq -r .variables.version centos.json)

help:
	@echo type make build-libvirt or make build-virtualbox

build-libvirt: centos-${VERSION}-amd64-libvirt.box

build-virtualbox: centos-${VERSION}-amd64-virtualbox.box

centos-${VERSION}-amd64-libvirt.box: ks.cfg upgrade.sh provision.sh centos.json Vagrantfile.template
	rm -f centos-${VERSION}-amd64-libvirt.box
	sed 's,sda,vda,g' ks.cfg >ks_libvirt.cfg.tmp
	PACKER_KEY_INTERVAL=10ms packer build -only=centos-${VERSION}-amd64-libvirt -on-error=abort -var ks=ks_libvirt.cfg.tmp centos.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f centos-${VERSION}-amd64 centos-${VERSION}-amd64-libvirt.box

centos-${VERSION}-amd64-virtualbox.box: ks.cfg upgrade.sh provision.sh centos.json
	rm -f centos-${VERSION}-amd64-virtualbox.box
	packer build -only=centos-${VERSION}-amd64-virtualbox -on-error=abort centos.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f centos-${VERSION}-amd64 centos-${VERSION}-amd64-virtualbox.box

.PHONY: buid-libvirt build-virtualbox