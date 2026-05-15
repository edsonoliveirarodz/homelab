variable "proxmox_ssh_username" {
  description = "SSH user for Proxmox node access (used for snippets upload)"
  type        = string
  default     = "root"
}

variable "proxmox_endpoint" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token (format: user@realm!tokenid=secret)"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

variable "proxmox_node_address" {
  description = "Proxmox node IP address (used for SSH connection)"
  type        = string
}

variable "template_id" {
  description = "VM ID of the template to clone"
  type        = number
}

variable "snippets_storage" {
  description = "Proxmox storage for cloud-init snippets"
  type        = string
}

variable "disk_storage" {
  description = "Proxmox storage for VM disks"
  type        = string
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
}

variable "network_gateway" {
  description = "Network gateway"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "control_plane" {
  description = "Control-plane node configuration"
  type = object({
    name            = string
    vm_id           = number
    ip              = string
    cores           = number
    memory          = number
    disk_size       = number
    bios            = string
    scsi_hardware   = string
    stop_on_destroy = bool
  })
}

variable "worker_count" {
  description = "Number of cluster workers"
  type        = number
  default     = 1
}

variable "ceph_disk_size" {
  description = "Extra disk size in GB for Ceph OSD on each worker (0 = disabled)"
  type        = number
  default     = 0
}

variable "workers" {
  description = "List of cluster workers"
  type = list(object({
    name            = string
    vm_id           = number
    ip              = string
    cores           = number
    memory          = number
    disk_size       = number
    bios            = string
    scsi_hardware   = string
    stop_on_destroy = bool
  }))
}
