variable "proxmox_node"         { type = string }
variable "template_id"          { type = number }
variable "snippets_storage"     { type = string }
variable "disk_storage"         { type = string }
variable "network_bridge"       { type = string }
variable "network_gateway"      { type = string }
variable "ssh_public_key"       { type = string }
variable "name"                 { type = string }
variable "vm_id"                { type = number }
variable "ip"                   { type = string }
variable "cores"                { type = number }
variable "memory"               { type = number }
variable "disk_size"            { type = number }
variable "tags"                 { type = list(string) }
variable "bios"                 { type = string }
variable "scsi_hardware"        { type = string }
variable "stop_on_destroy"      { type = bool }
variable "ceph_disk_size" {
  type    = number
  default = 0
}