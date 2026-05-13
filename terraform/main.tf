terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.106"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true # Disable if you have a valid certificate.

  ssh {
    agent    = true
    username = var.proxmox_ssh_username

    node {
      name    = var.proxmox_node
      address = var.proxmox_node_address
    }
  }
}

module "control_plane" {
  source = "./modules/k8s-node"

  proxmox_node     = var.proxmox_node
  template_id      = var.template_id
  snippets_storage = var.snippets_storage
  disk_storage     = var.disk_storage
  network_bridge   = var.network_bridge
  network_gateway  = var.network_gateway
  ssh_public_key   = var.ssh_public_key

  name            = var.control_plane.name
  vm_id           = var.control_plane.vm_id
  ip              = var.control_plane.ip
  cores           = var.control_plane.cores
  memory          = var.control_plane.memory
  disk_size       = var.control_plane.disk_size
  bios            = var.control_plane.bios
  scsi_hardware   = var.control_plane.scsi_hardware
  stop_on_destroy = var.control_plane.stop_on_destroy

  ceph_disk_size = 0

  tags = ["k8s", "control-plane"]
}

module "workers" {
  source   = "./modules/k8s-node"
  for_each = { for w in local.workers_generated : w.name => w }

  proxmox_node     = var.proxmox_node
  template_id      = var.template_id
  snippets_storage = var.snippets_storage
  disk_storage     = var.disk_storage
  network_bridge   = var.network_bridge
  network_gateway  = var.network_gateway
  ssh_public_key   = var.ssh_public_key

  name            = each.value.name
  vm_id           = each.value.vm_id
  ip              = each.value.ip
  cores           = each.value.cores
  memory          = each.value.memory
  disk_size       = each.value.disk_size
  bios            = each.value.bios
  scsi_hardware   = each.value.scsi_hardware
  stop_on_destroy = each.value.stop_on_destroy
  ceph_disk_size  = each.value.ceph_disk_size

  tags = ["k8s", "worker"]
}
