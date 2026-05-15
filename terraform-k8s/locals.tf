locals {
  node_defaults = {
    bios            = "ovmf"
    scsi_hardware   = "virtio-scsi-single"
    stop_on_destroy = true
    cores           = 4
    memory          = 8192
    disk_size       = 32
  }

  base_vm_id    = 101
  base_ip_octet = 202
  worker_count  = var.worker_count

  workers_generated = [
    for i in range(local.worker_count) : merge(
      local.node_defaults,
      {
        name           = "k8s-worker-${i + 1}"
        vm_id          = local.base_vm_id + i
        ip             = "192.168.1.${local.base_ip_octet + i}/24"
        ceph_disk_size = var.ceph_disk_size
      }
    )
  ]
}
