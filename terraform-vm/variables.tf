variable "proxmox_ssh_username" {
  type    = string
  default = "root"
}

variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_api_token" {
  type      = string
  sensitive = true
}

variable "proxmox_node" {
  type = string
}

variable "proxmox_node_address" {
  type = string
}

variable "template_id" {
  type = number
}

variable "snippets_storage" {
  type = string
}

variable "disk_storage" {
  type = string
}

variable "network_bridge" {
  type = string
}

variable "network_gateway" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "vm" {
  description = "VM configuration"
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
    tags            = list(string)
  })
}

variable "extra_disk_size" {
  description = "Extra disk size in GB (0 = disabled)"
  type        = number
  default     = 0
}
