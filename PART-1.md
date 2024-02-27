# Build images with `packer`

## Build an Ubuntu image from installer ISO with `autoinstall`

Takes around ~6 minutes on an i7 with SSDs (excluding download)

```shell
packer build -var-file=packer/ubuntu/ubuntu2204-autoinstall.pkrvars.hcl packer/ubuntu/ubuntu-autoinstall.pkr.hcl
```

## Build an Ubuntu image from cloud image with `cloud-init`

Takes around ~1 minutes on an i7 with SSDs (excluding download)

```shell
packer build -var-file=packer/ubuntu/ubuntu2204-cloudimg.pkrvars.hcl packer/ubuntu/ubuntu-cloudimg.pkr.hcl
```

# Run images with `virtinst`

## Start a VM with `cloud-init`
To configure the VM with `cloud-init`, we provide a `user-data` file via CD-ROM.

```shell
name=ubuntu2204-test
source=/data2/runner/images/ubuntu2204-autoinstall.qcow2
#source=/data2/runner/images/ubuntu2204-cloudimg.qcow2
disk_path=/data2/vms
cd_path=vms/ubuntu2204-test

# commands to cleanup
virsh destroy $name
virsh undefine $name --nvram
rm -f $disk_path/$name.qcow2 $disk_path/$name-cidata.iso

# create CD-ROM and copy disk image
mkisofs -o $disk_path/$name-cidata.iso -J -R -volid cidata -r $cd_path
cp $source /data2/vms/$name.qcow2

virt-install \
  --name=$name \
  --os-variant=win2k22 \
  --ram=4096 \
  --vcpus=4 \
  --cpu host-passthrough \
  --disk path=$disk_path/$name.qcow2,bus=virtio,cache=none \
  --disk path=$disk_path/$name-cidata.iso,device=cdrom \
  --noautoconsole \
  --graphics=vnc,port=5991 \
  --network network=default,model=virtio \
  --boot uefi
```