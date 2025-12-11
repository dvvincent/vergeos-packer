packer {
  required_plugins {
    vergeio = {
      source  = "github.com/verge-io/vergeio"
      version = ">=0.1.1"
    }
  }
}

# Variables
variable "vergeio_endpoint" {
  type    = string
  default = "192.168.1.111"
}

variable "vergeio_username" {
  type    = string
  default = "admin"
}

variable "vergeio_password" {
  type      = string
  sensitive = true
  default   = "Algom@Secure"
}

variable "network_name" {
  type        = string
  default     = "External"
  description = "Name of the VergeOS network to attach to"
}

# Network data source - discover network by name instead of hardcoding ID
data "vergeio-networks" "target_network" {
  vergeio_endpoint = var.vergeio_endpoint
  vergeio_username = var.vergeio_username
  vergeio_password = var.vergeio_password
  vergeio_insecure = true
  vergeio_port     = 443

  filter_name = var.network_name
}

# VergeIO VM source - Import from Debian 13 cloud image
source "vergeio" "debian13_cloud" {
  vergeio_endpoint = var.vergeio_endpoint
  vergeio_username = var.vergeio_username
  vergeio_password = var.vergeio_password
  vergeio_insecure = true
  vergeio_port     = 443

  name        = "packer-debian13-cloud"
  description = "Debian 13 from cloud image"
  os_family   = "linux"
  cpu_cores   = 2
  ram         = 2048
  power_state = true
  guest_agent = true

  # Import from Debian 13 cloud image (qcow2)
  vm_disks {
    name           = "System Disk"
    disksize       = 20
    interface      = "virtio-scsi"
    preferred_tier = 1
    media          = "import"
    media_source   = 72  # debian-13-generic-amd64-bebb4d32.qcow2
  }

  vm_nics {
    name             = "primary_nic"
    vnet             = data.vergeio-networks.target_network.networks[0].id
    interface        = "virtio"
    assign_ipaddress = true
    enabled          = true
  }

  # Cloud-init for cloud images
  cloud_init_data_source = "nocloud"
  
  cloud_init_files {
    name  = "user-data"
    files = ["cloud-init/cloud-user-data.yml"]
  }

  cloud_init_files {
    name  = "meta-data"
    files = ["cloud-init/meta-data.yml"]
  }

  communicator = "ssh"
  ssh_username = "debian"  # Default user for Debian cloud images
  ssh_password = "packer123"
  ssh_timeout  = "20m"

  power_on_timeout = "5m"
  shutdown_command = "sudo shutdown -P now"
  shutdown_timeout = "5m"
}

build {
  sources = ["source.vergeio.debian13_cloud"]

  provisioner "shell" {
    inline = [
      "echo 'System Information:'",
      "uname -a",
      "cat /etc/debian_version"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget vim htop git"
    ]
  }
}
