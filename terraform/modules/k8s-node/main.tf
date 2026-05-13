resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = var.snippets_storage
  node_name    = var.proxmox_node

  source_raw {
    data = templatefile("${path.root}/../cloud-init/init.yml", {
      hostname       = var.name
      ssh_public_key = var.ssh_public_key
    })
    file_name = "cloud-init-${var.vm_id}.yml"
  }
}

resource "proxmox_virtual_environment_vm" "node" {
  name            = var.name
  node_name       = var.proxmox_node
  vm_id           = var.vm_id
  tags            = var.tags
  bios            = var.bios
  scsi_hardware   = var.scsi_hardware
  stop_on_destroy = var.stop_on_destroy

  clone {
    vm_id = var.template_id
    full  = true
  }

  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.disk_storage
    interface    = "scsi0"
    size         = var.disk_size
    discard      = "on"
    iothread     = true
    ssd          = true
  }

  dynamic "disk" {
    for_each = var.ceph_disk_size > 0 ? [var.ceph_disk_size] : []
    content {
      datastore_id = var.disk_storage
      interface    = "scsi1"
      size         = disk.value
      discard      = "on"
      iothread     = true
    }
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
        address = var.ip
        gateway = var.network_gateway
      }
    }

  }

  agent {
    enabled = true
  }

  # Wait for the guest agent to respond before considering the VM ready.
  timeout_create = 120
}
