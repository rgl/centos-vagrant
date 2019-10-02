VERSION=$(shell jq -r .variables.version centos.json)

help:
	@echo type make build-libvirt or make build-virtualbox

build-libvirt: centos-${VERSION}-amd64-libvirt.box

build-virtualbox: centos-${VERSION}-amd64-virtualbox.box

centos-${VERSION}-amd64-libvirt.box: ks.cfg upgrade.sh provision.sh centos.json Vagrantfile.template
	rm -f $@
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=centos-${VERSION}-amd64-libvirt -on-error=abort centos.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f centos-${VERSION}-amd64 centos-${VERSION}-amd64-libvirt.box

centos-${VERSION}-amd64-virtualbox.box: ks.cfg upgrade.sh provision.sh centos.json
	rm -f $@
	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=centos-${VERSION}-amd64-virtualbox -on-error=abort centos.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f centos-${VERSION}-amd64 centos-${VERSION}-amd64-virtualbox.box

.PHONY: buid-libvirt build-virtualbox
