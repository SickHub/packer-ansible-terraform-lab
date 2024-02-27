# Build images with packer

## Build an Ubuntu image from installer ISO with `autoinstall`

```shell
# takes around ~6 minutes on an i7 with SSDs (excluding download)
packer build -var-file=packer/ubuntu/ubuntu2204-autoinstall.pkrvars.hcl packer/ubuntu/ubuntu-autoinstall.pkr.hcl
```

## Build an Ubuntu image from cloud image with `cloud-init`
Takes around ~X minutes on an i7 with SSDs (excluding download)
```shell
packer build -var-file=packer/ubuntu/ubuntu2204-cloudimage.pkrvars.hcl packer/ubuntu/ubuntu-cloudimage.pkr.hcl
```
