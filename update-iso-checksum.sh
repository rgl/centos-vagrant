#!/bin/bash
# this will update the centos.json file with the current netboot image checksum.
# see https://wiki.centos.org/Download/Verify
# see https://www.centos.org/keys/
set -eux
key_url=https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
key_file=$(basename $key_url)
curl -o $key_file --silent --show-error $key_url
gpg --import $key_file
iso_url=$(jq -r '.variables.iso_url' centos.json)
iso_checksum_url=$(dirname $iso_url)/CHECKSUM.asc
iso_checksum_file=$(basename $iso_checksum_url)
curl -O --silent --show-error $iso_checksum_url
gpg --verify $iso_checksum_file
iso_checksum=$(grep $(basename $iso_url) $iso_checksum_file | awk '/SHA256 /{print $4}')
sed -i -E "s,(\"iso_checksum\": \")([a-f0-9]+)(\"),\\1$iso_checksum\\3,g" centos.json
rm $iso_checksum_file $key_file
echo 'iso_checksum updated successfully'
