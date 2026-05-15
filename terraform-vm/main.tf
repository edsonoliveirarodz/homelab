terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.106"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true

  ssh {
    agent    = true
    username = var.proxmox_ssh_username

    node {
      name    = var.proxmox_node
      address = var.proxmox_node_address
    }
  }
}

resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = var.snippets_storage
  node_name    = var.proxmox_node

  source_raw {
    data = templatefile("${path.module}/cloud-init/cloud-init.yml.tftpl", {
      hostname       = var.vm.name
      ssh_public_key = var.ssh_public_key
    })
    file_name = "cloud-init-vm-${var.vm.vm_id}.yml"
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  name            = var.vm.name
  node_name       = var.proxmox_node
  vm_id           = var.vm.vm_id
  tags            = var.vm.tags
  bios            = var.vm.bios
  scsi_hardware   = var.vm.scsi_hardware
  stop_on_destroy = var.vm.stop_on_destroy

  clone {
    vm_id = var.template_id
    full  = true
  }

  cpu {
    cores = var.vm.cores
    type  = "host"
  }

  memory {
    dedicated = var.vm.memory
  }

  disk {
    datastore_id = var.disk_storage
    interface    = "scsi0"
    size         = var.vm.disk_size
    discard      = "on"
    iothread     = true
    ssd          = true
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    datastore_id      = var.disk_storage
    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id

    ip_config {
      ipv4 {
        address = var.vm.ip
        gateway = var.network_gateway
      }
    }
  }

  agent {
    enabled = true
  }

  timeout_create = 120
}
