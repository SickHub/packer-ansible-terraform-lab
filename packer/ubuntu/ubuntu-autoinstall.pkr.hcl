variables {
  # iso_url      = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso"
  iso_url      = "/data2/runner/images/Ubuntu2204-Server.iso"
  iso_checksum = "sha256:45f873de9f8cb637345d6e66a583762730bbea30277ef7b32c9c3bd6700a32b2"
  build_dir    = "/data2/runner/build"
  build_name   = "ubuntu2204-autoinstall"
  output_dir   = "/data2/runner/images"
  image_name   = "ubuntu2204-autoinstall"
  http_dir     = "packer/ubuntu/autoinstall"
}

source "qemu" "ubuntu" {
  accelerator       = "kvm"
  # q35 does not create a floppy by default
  machine_type      = "q35"
  boot_key_interval = "50ms"
  boot_command      = [
    "<esc><wait>c", 
    "linux /casper/vmlinuz ", "--- ", 
    "autoinstall ", 
    "ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'", 
    "<enter><wait>", 
    "initrd /casper/initrd<enter>", 
    "boot<enter>"]
  boot_wait         = "10s"
  disk_compression  = false
  disk_discard      = "unmap"
  disk_interface    = "virtio"
  disk_size         = 10000
  firmware          = "/usr/share/ovmf/OVMF.fd"
  format            = "qcow2"
  headless          = true
  host_port_max     = 2209
  host_port_min     = 2201
  http_directory    = "${var.http_dir}"
  http_port_max     = 10089
  http_port_min     = 10081
  iso_checksum      = "${var.iso_checksum}"
  iso_url           = "${var.iso_url}"
  net_device        = "virtio-net"
  output_directory  = "${var.build_dir}/${var.build_name}"
  qemuargs          = [
    ["-m", "2048M"], 
    ["-smp", "cores=2,threads=2"]
  ]
  skip_compaction   = true
  shutdown_command  = "echo 'packer' | sudo -S shutdown -P now"
  ssh_password      = "packer"
  ssh_port          = 22
  ssh_username      = "ubuntu"
  ssh_wait_timeout  = "20m"
  vm_name           = "${var.image_name}"
  vnc_bind_address  = "0.0.0.0"
  vnc_port_max      = 5909
  vnc_port_min      = 5901
}

build {
  name = "${var.build_name}"
  sources = ["source.qemu.ubuntu"]

  # cleanup within the image
  provisioner "shell" {
    inline = [
      "echo 'packer' | sudo apt upgrade -y",
      "echo 'packer' | sudo apt auto-remove -y",
      "echo 'packer' | sudo apt clean -y",
      "echo 'packer' | sudo rm -rf /var/lib/apt/lists/*",
      "echo 'packer' | sudo cloud-init clean",
      # reset config and enable networking via cloud-init
      "echo 'packer' | sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "echo 'packer' | sudo rm -f /etc/cloud/cloud.cfg.d/99-installer.cfg",
    ]
  }

  # cleanup and compress the image
  post-processor "shell-local" {
    inline = [
      "virt-sysprep -a ${var.build_dir}/${var.build_name}/${var.image_name}",
      "qemu-img convert -W -c -O qcow2 ${var.build_dir}/${var.build_name}/${var.image_name} ${var.output_dir}/${var.image_name}.qcow2",
      "rm -rf ${var.build_dir}/${var.build_name}",
      # generate pkrvars for a build referencing this image (url + checksum)
      "checksum=$(sha256sum ${var.output_dir}/${var.image_name}.qcow2 | awk '{print $1}')",
      "echo 'iso_url = \"${var.output_dir}/${var.image_name}.qcow2\"\niso_checksum = \"'sha256:$checksum'\"' > packer/linux/${var.image_name}.pkrvars.hcl"
    ]
  }
}
