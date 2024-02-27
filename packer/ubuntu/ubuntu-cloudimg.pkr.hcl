packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variables {
  # iso_url      = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
  iso_url      = "/data2/runner/images/Ubuntu2204-Server-cloudimg.img"
  iso_checksum = "sha256:3f48ed24115b50a6f48a3915d9b661388767cd8b6c42bdebfc3ea2cdda235100"
  build_dir    = "/data/runner/build"
  build_name   = "cloudimg-gitlab-runner"
  output_dir   = "/data/runner/images"
  image_name   = "cloudimg-gitlab-runner"
  cd_data      = "cloudimg"
  vnc_port_max = 5909
  vnc_port_min = 5901
  disk_size    = 20000
}

source "qemu" "gitlab-runner" {
  accelerator       = "kvm"
  # q35 does not create a floppy by default
  machine_type      = "q35"
  boot_command      = ["<enter>"]
  boot_wait         = "5s"
  cd_files          = ["${var.cd_data}/*"]
  cd_label          = "cidata"
  disk_image        = true
  disk_compression  = false
  disk_discard      = "unmap"
  disk_interface    = "virtio"
  disk_size         = "${var.disk_size}"
  firmware          = "/usr/share/ovmf/OVMF.fd"
  format            = "qcow2"
  headless          = true
  host_port_max     = 2209
  host_port_min     = 2201
  iso_checksum      = "${var.iso_checksum}"
  iso_url           = "${var.iso_url}"
  net_device        = "virtio-net"
  output_directory  = "${var.build_dir}/${var.build_name}"
  qemuargs          = [["-m", "4096M"], ["-smp", "cores=4,threads=1"], ["-enable-kvm"]]
  skip_compaction   = true
  shutdown_command  = "echo 'packer' | sudo -S shutdown -P now"
  ssh_password      = "packer"
  ssh_port          = 22
  ssh_username      = "ubuntu"
  ssh_wait_timeout  = "10m"
  vm_name           = "${var.image_name}"
  vnc_bind_address  = "0.0.0.0"
  vnc_port_max      = "${var.vnc_port_max}"
  vnc_port_min      = "${var.vnc_port_min}"
}

build {
  name = "${var.build_name}"
  sources = ["source.qemu.gitlab-runner"]
  
  provisioner "shell" {
    inline = [
      # retries due to apt-lock
      "for i in $(seq 1 5); do sudo apt-get autoremove -y && break; sleep 5; done",
      "for i in $(seq 1 5); do sudo apt-get clean -y && break; sleep 5; done",
      "sudo rm -rf /var/lib/apt/lists/*",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/tmp/*",
      # remove subiquity file disabling cloudinit networking (if exists)
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      # reset cloud-init - if this is not a final image
      "sudo cloud-init clean"
    ]
  }

  post-processor "shell-local" {
    inline = [
      "virt-sysprep -a ${var.build_dir}/${var.build_name}/${var.image_name}",
      "qemu-img convert -W -m 16 -c -O qcow2 ${var.build_dir}/${var.build_name}/${var.image_name} ${var.output_dir}/${var.image_name}.qcow2",
      "rm -rf ${var.build_dir}/${var.build_name}",
    ]
  }
}
